import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/auth/session_manager.dart';
import 'package:meu_bebe/app/core/auth/token_storage.dart';
import 'package:meu_bebe/app/core/constants/local_storage_constants.dart';
import 'package:meu_bebe/app/core/rest_client/interceptors/auth_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _refreshPath = '/api/v1/auth/refresh';

class _FakeRequestHandler extends RequestInterceptorHandler {
  RequestOptions? nextOptions;

  @override
  void next(RequestOptions requestOptions) => nextOptions = requestOptions;
}

class _FakeErrorHandler extends ErrorInterceptorHandler {
  DioException? nextError;
  Response? resolved;

  @override
  void next(DioException error) => nextError = error;

  @override
  void resolve(Response response) => resolved = response;
}

class _FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int status, Map<String, dynamic> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {'content-type': ['application/json']},
    );

DioException _unauthorized({
  required Map<String, dynamic> extra,
  String path = '/api/v1/gestantes/me',
}) {
  final requestOptions = RequestOptions(path: path, extra: extra);
  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: requestOptions, statusCode: 401),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthInterceptor.onRequest', () {
    test('adiciona Bearer quando DIO_AUTH_KEY true e há access token', () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageConstants.accessToken: 'access-token',
      });
      final interceptor = AuthInterceptor(client: Dio());
      final options = RequestOptions(
        path: '/api/v1/gestantes/me',
        extra: {'DIO_AUTH_KEY': true},
      );
      final handler = _FakeRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.nextOptions!.headers['Authorization'], 'Bearer access-token');
    });

    test('não adiciona Authorization quando DIO_AUTH_KEY é false', () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageConstants.accessToken: 'access-token',
      });
      final interceptor = AuthInterceptor(client: Dio());
      final options = RequestOptions(
        path: '/api/v1/auth/login',
        extra: {'DIO_AUTH_KEY': false},
      );
      final handler = _FakeRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.nextOptions!.headers.containsKey('Authorization'), isFalse);
    });

    test('remove Authorization pré-existente e aplica o token atual', () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageConstants.accessToken: 'access-token',
      });
      final interceptor = AuthInterceptor(client: Dio());
      final options = RequestOptions(
        path: '/api/v1/gestantes/me',
        extra: {'DIO_AUTH_KEY': true},
        headers: {'Authorization': 'Bearer stale'},
      );
      final handler = _FakeRequestHandler();

      await interceptor.onRequest(options, handler);

      expect(handler.nextOptions!.headers['Authorization'], 'Bearer access-token');
    });
  });

  group('AuthInterceptor.onError', () {
    test('não-401 passa direto, sem refresh', () async {
      var navigations = 0;
      final session = SessionManager(navigateToLogin: () async => navigations++);
      final interceptor = AuthInterceptor(client: Dio(), session: session);

      final requestOptions = RequestOptions(
        path: '/api/v1/gestantes/me',
        extra: {'DIO_AUTH_KEY': true},
      );
      final err = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 500,
        ),
      );
      final handler = _FakeErrorHandler();

      await interceptor.onError(err, handler);

      expect(handler.nextError, same(err));
      expect(handler.resolved, isNull);
      expect(navigations, 0);
    });

    test('401 em requisição não-autenticada passa direto', () async {
      var navigations = 0;
      final session = SessionManager(navigateToLogin: () async => navigations++);
      final interceptor = AuthInterceptor(client: Dio(), session: session);

      final err = _unauthorized(extra: {'DIO_AUTH_KEY': false});
      final handler = _FakeErrorHandler();

      await interceptor.onError(err, handler);

      expect(handler.nextError, same(err));
      expect(navigations, 0);
    });

    test('401 sem refresh token encerra a sessão e repassa o erro', () async {
      var navigations = 0;
      final session = SessionManager(navigateToLogin: () async => navigations++);
      final interceptor = AuthInterceptor(client: Dio(), session: session);

      final err = _unauthorized(extra: {'DIO_AUTH_KEY': true});
      final handler = _FakeErrorHandler();

      await interceptor.onError(err, handler);

      expect(handler.nextError, same(err));
      expect(navigations, 1);
    });

    test('refresh bem-sucedido salva tokens e refaz a requisição com novo Bearer', () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageConstants.refreshToken: 'old-refresh',
      });

      final adapter = _FakeAdapter((options) async {
        if (options.path == _refreshPath) {
          return _jsonResponse(200, {
            'user': {'id': 'u1', 'email': 'a@b.com', 'is_active': true},
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          });
        }
        return _jsonResponse(200, {'id': 'g1'});
      });
      final dio = Dio();
      dio.httpClientAdapter = adapter;

      var navigations = 0;
      final session = SessionManager(navigateToLogin: () async => navigations++);
      final interceptor = AuthInterceptor(client: dio, session: session);

      final err = _unauthorized(extra: {'DIO_AUTH_KEY': true});
      final handler = _FakeErrorHandler();

      await interceptor.onError(err, handler);

      expect(handler.resolved, isNotNull);
      expect(handler.resolved!.statusCode, 200);
      expect(navigations, 0);

      // tokens renovados persistidos.
      final storage = TokenStorage();
      expect(await storage.getAccessToken(), 'new-access');
      expect(await storage.getRefreshToken(), 'new-refresh');

      // refez a requisição original uma vez, com o novo Bearer e DIO_REFRESHED.
      expect(adapter.requests.length, 2);
      final retry = adapter.requests.last;
      expect(retry.extra['DIO_REFRESHED'], isTrue);
      expect(retry.headers['Authorization'], 'Bearer new-access');
    });

    test('refresh falha encerra a sessão e repassa o erro original', () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageConstants.refreshToken: 'old-refresh',
      });

      final adapter = _FakeAdapter(
        (options) async => _jsonResponse(401, {'code': 'unauthorized', 'message': 'expired'}),
      );
      final dio = Dio();
      dio.httpClientAdapter = adapter;

      var navigations = 0;
      final session = SessionManager(navigateToLogin: () async => navigations++);
      final interceptor = AuthInterceptor(client: dio, session: session);

      final err = _unauthorized(extra: {'DIO_AUTH_KEY': true});
      final handler = _FakeErrorHandler();

      await interceptor.onError(err, handler);

      expect(handler.nextError, same(err));
      expect(navigations, 1);
    });

    test('refresh com corpo inválido encerra a sessão', () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageConstants.refreshToken: 'old-refresh',
      });

      final adapter = _FakeAdapter(
        (options) async => _jsonResponse(200, {'unexpected': true}),
      );
      final dio = Dio();
      dio.httpClientAdapter = adapter;

      var navigations = 0;
      final session = SessionManager(navigateToLogin: () async => navigations++);
      final interceptor = AuthInterceptor(client: dio, session: session);

      final err = _unauthorized(extra: {'DIO_AUTH_KEY': true});
      final handler = _FakeErrorHandler();

      await interceptor.onError(err, handler);

      expect(handler.nextError, same(err));
      expect(navigations, 1);
    });
  });

  group('AuthInterceptor.onError — refresh concorrente (single-flight)', () {
    test('6 401 simultâneos → UM ÚNICO refresh compartilhado', () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageConstants.refreshToken: 'old-refresh',
      });

      final adapter = _FakeAdapter((options) async {
        if (options.path == _refreshPath) {
          return _jsonResponse(200, {
            'user': {'id': 'u1', 'email': 'a@b.com', 'is_active': true},
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          });
        }
        return _jsonResponse(200, {'id': 'g1'});
      });
      final dio = Dio();
      dio.httpClientAdapter = adapter;

      var navigations = 0;
      final session = SessionManager(navigateToLogin: () async => navigations++);
      final interceptor = AuthInterceptor(client: dio, session: session);

      final handlers =
          List<_FakeErrorHandler>.generate(6, (_) => _FakeErrorHandler());
      final futures = <Future<void>>[];
      for (var i = 0; i < 6; i++) {
        final err = _unauthorized(extra: {'DIO_AUTH_KEY': true});
        futures.add(interceptor.onError(err, handlers[i]));
      }

      await Future.wait(futures);

      final refreshCalls =
          adapter.requests.where((r) => r.path == _refreshPath).length;
      expect(refreshCalls, 1);
      expect(navigations, 0);

      final retries =
          adapter.requests.where((r) => r.path != _refreshPath).toList();
      expect(retries, hasLength(6));
      for (final retry in retries) {
        expect(retry.extra['DIO_REFRESHED'], isTrue);
        expect(retry.headers['Authorization'], 'Bearer new-access');
      }
      for (final h in handlers) {
        expect(h.resolved, isNotNull);
        expect(h.resolved!.statusCode, 200);
      }
    });

    test('refresh concorrente falha → UM ÚNICO refresh e UMA ÚNICA navegação',
        () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageConstants.refreshToken: 'old-refresh',
      });

      final adapter = _FakeAdapter(
        (options) async =>
            _jsonResponse(401, {'code': 'unauthorized', 'message': 'expired'}),
      );
      final dio = Dio();
      dio.httpClientAdapter = adapter;

      var navigations = 0;
      final session = SessionManager(navigateToLogin: () async => navigations++);
      final interceptor = AuthInterceptor(client: dio, session: session);

      final handlers =
          List<_FakeErrorHandler>.generate(6, (_) => _FakeErrorHandler());
      final errs = <DioException>[];
      final futures = <Future<void>>[];
      for (var i = 0; i < 6; i++) {
        final err = _unauthorized(extra: {'DIO_AUTH_KEY': true});
        errs.add(err);
        futures.add(interceptor.onError(err, handlers[i]));
      }

      await Future.wait(futures);

      final refreshCalls =
          adapter.requests.where((r) => r.path == _refreshPath).length;
      expect(refreshCalls, 1);
      expect(navigations, 1);

      for (var i = 0; i < 6; i++) {
        expect(handlers[i].nextError, same(errs[i]));
        expect(handlers[i].resolved, isNull);
      }
    });

    test('nova onda de 401 após refresh concluído inicia um refresh novo',
        () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageConstants.refreshToken: 'old-refresh',
      });

      final adapter = _FakeAdapter((options) async {
        if (options.path == _refreshPath) {
          return _jsonResponse(200, {
            'user': {'id': 'u1', 'email': 'a@b.com', 'is_active': true},
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          });
        }
        return _jsonResponse(200, {'id': 'g1'});
      });
      final dio = Dio();
      dio.httpClientAdapter = adapter;

      var navigations = 0;
      final session = SessionManager(navigateToLogin: () async => navigations++);
      final interceptor = AuthInterceptor(client: dio, session: session);

      int refreshCount() =>
          adapter.requests.where((r) => r.path == _refreshPath).length;

      await interceptor.onError(
        _unauthorized(extra: {'DIO_AUTH_KEY': true}),
        _FakeErrorHandler(),
      );
      expect(refreshCount(), 1);

      await interceptor.onError(
        _unauthorized(extra: {'DIO_AUTH_KEY': true}),
        _FakeErrorHandler(),
      );
      expect(refreshCount(), 2);
      expect(navigations, 0);
    });
  });
}
