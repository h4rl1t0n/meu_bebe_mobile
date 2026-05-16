import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/exceptions/auth_exception.dart';
import 'user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final DioForNative client;
  UserRepositoryImpl({required this.client});

  @override
  Future<Result<String, AuthException>> login(String email, String password) async {
    try {
      final Response(data: {'access_token': accessToken}) = await client.post(
        '/auth',
        data: {'email': email, 'password': password},
      );
      return Success(accessToken);
    } on DioException catch (e, s) {
      log('Erro ao realizar login', error: e, stackTrace: s);
      return switch (e) {
        DioException(response: Response(statusCode: HttpStatus.forbidden)) =>
          Error(AuthUnauthorizedException()),
        _ => Error(AuthError(message: 'Erro ao realizar login')),
      };
    }
  }
}
