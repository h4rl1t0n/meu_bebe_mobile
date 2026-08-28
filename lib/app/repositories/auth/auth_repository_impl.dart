import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/auth/auth_models.dart';
import 'auth_repository.dart';

/// Implementação HTTP do [AuthRepository].
///
/// Caminhos congelados (contrato FASE 8C), todos sob ``/api/v1/auth``. Os
/// pedidos SEM autenticação (login/register/refresh/logout) enviam
/// ``DIO_AUTH_KEY = false``; `me` envia ``DIO_AUTH_KEY = true``. Isso torna o
/// envio do ``Authorization`` determinístico, independentemente do estado do
/// client.
class AuthRepositoryImpl implements AuthRepository {
  static const String registerPath = '/api/v1/auth/register';
  static const String loginPath = '/api/v1/auth/login';
  static const String refreshPath = '/api/v1/auth/refresh';
  static const String logoutPath = '/api/v1/auth/logout';
  static const String mePath = '/api/v1/auth/me';

  final DioForNative client;
  final BackendDioExceptionMapper _mapper;

  AuthRepositoryImpl({required this.client})
    : _mapper = const BackendDioExceptionMapper();

  static const _unAuth = {'DIO_AUTH_KEY': false};
  static const _auth = {'DIO_AUTH_KEY': true};

  @override
  Future<Result<TokenResponseModel, BackendFailure>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await client.post(
        loginPath,
        data: {'email': email, 'password': password},
        options: Options(extra: _unAuth),
      );

      final token = TokenResponseModel.tryParse(response.data);
      if (token == null) return const Error(UnexpectedFailure());
      return Success(token);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Error(InvalidCredentialsFailure());
      }
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<TokenResponseModel, BackendFailure>> register(
    String email,
    String password,
  ) async {
    try {
      final response = await client.post(
        registerPath,
        data: {'email': email, 'password': password},
        options: Options(extra: _unAuth),
      );

      final token = TokenResponseModel.tryParse(response.data);
      if (token == null) return const Error(UnexpectedFailure());
      return Success(token);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<TokenResponseModel, BackendFailure>> refresh(
    String refreshToken,
  ) async {
    try {
      final response = await client.post(
        refreshPath,
        data: {'refresh_token': refreshToken},
        options: Options(extra: _unAuth),
      );

      final token = TokenResponseModel.tryParse(response.data);
      if (token == null) return const Error(UnexpectedFailure());
      return Success(token);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<Unit, BackendFailure>> logout(String refreshToken) async {
    try {
      await client.post(
        logoutPath,
        data: {'refresh_token': refreshToken},
        options: Options(extra: _unAuth),
      );
      return const Success(unit);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<UserResponseModel, BackendFailure>> me() async {
    try {
      final response = await client.get(
        mePath,
        options: Options(extra: _auth),
      );

      final user = UserResponseModel.tryParse(response.data);
      if (user == null) return const Error(UnexpectedFailure());
      return Success(user);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }
}
