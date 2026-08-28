import 'package:dio/dio.dart';

import '../../auth/session_manager.dart';
import '../../auth/token_storage.dart';
import '../../../model/auth/auth_models.dart';

/// Injetor de ``Authorization`` + renovação de sessão (FASE 9A).
///
/// - `onRequest`: remove qualquer ``Authorization`` pré-existente e só o
///   adiciona (`Bearer <access>`) quando `extra['DIO_AUTH_KEY'] == true`.
/// - `onError`: em ``401`` de uma requisição AUTENTICADA (que ainda não passou
///   por refresh), tenta renovar a sessão UMA única vez via ``POST
///   /api/v1/auth/refresh`` e refaz a requisição original. A renovação NUNCA é
///   aplicada a ``/auth/login``, ``/auth/register``, ``/auth/refresh`` ou
///   ``/auth/logout`` (marcados com ``DIO_SKIP_REFRESH`` / sem auth), evitando
///   loop infinito. Em falha, limpa os tokens locais (a sessão cai e o app
///   volta ao login na próxima abertura).
final class AuthInterceptor extends Interceptor {
  final Dio client;
  final TokenStorage storage;
  final SessionManager session;

  AuthInterceptor({
    required this.client,
    TokenStorage? storage,
    SessionManager? session,
  })  : storage = storage ?? const TokenStorage(),
        session = session ?? SessionManager(storage: storage ?? const TokenStorage());

  static const _authHeaderKey = 'Authorization';
  static const _refreshPath = '/api/v1/auth/refresh';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final RequestOptions(:headers, :extra) = options;
    headers.remove(_authHeaderKey);

    if (extra case {'DIO_AUTH_KEY': true}) {
      final accessToken = await storage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        headers.addAll({_authHeaderKey: 'Bearer $accessToken'});
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;

    final isAuth = request.extra['DIO_AUTH_KEY'] == true;
    final skipRefresh = request.extra['DIO_SKIP_REFRESH'] == true;
    final alreadyRefreshed = request.extra['DIO_REFRESHED'] == true;
    final isRefreshEndpoint = request.path == _refreshPath;
    final isUnauthorized = err.response?.statusCode == 401;

    final shouldRefresh =
        isUnauthorized &&
        isAuth &&
        !skipRefresh &&
        !alreadyRefreshed &&
        !isRefreshEndpoint;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await session.handleSessionExpired();
      handler.next(err);
      return;
    }

    try {
      final refreshResponse = await client.post(
        _refreshPath,
        data: {'refresh_token': refreshToken},
        options: Options(
          extra: const {'DIO_AUTH_KEY': false, 'DIO_SKIP_REFRESH': true},
        ),
      );

      final token = TokenResponseModel.tryParse(refreshResponse.data);
      if (token == null) {
        await session.handleSessionExpired();
        handler.next(err);
        return;
      }

      await storage.saveTokens(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
      );

      // Refaz a requisição original UMA vez com o token renovado. O
      // `client.fetch` NÃO passa pelos interceptors, então o header é setado
      // aqui manualmente.
      final retryOptions = request;
      retryOptions.extra['DIO_AUTH_KEY'] = true;
      retryOptions.extra['DIO_REFRESHED'] = true;
      retryOptions.headers.remove(_authHeaderKey);
      retryOptions.headers[_authHeaderKey] = 'Bearer ${token.accessToken}';

      final retryResponse = await client.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await session.handleSessionExpired();
      handler.next(err);
    }
  }
}
