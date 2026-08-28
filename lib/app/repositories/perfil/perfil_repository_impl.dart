import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/auth/auth_models.dart';
import '../../model/gestacao/gestacao_model.dart';
import '../../model/gestante/gestante_model.dart';
import 'perfil_repository.dart';

/// Implementação HTTP do [PerfilRepository] (contrato congelado FASE 8C/8D).
class PerfilRepositoryImpl implements PerfilRepository {
  static const String mePath = '/api/v1/auth/me';
  static const String gestantePath = '/api/v1/gestantes/me';
  static const String gestacaoAtualPath = '/api/v1/gestacoes/atual';

  final DioForNative client;
  final BackendDioExceptionMapper _mapper;

  PerfilRepositoryImpl({required this.client})
    : _mapper = const BackendDioExceptionMapper();

  static const _auth = {'DIO_AUTH_KEY': true};

  @override
  Future<Result<UserResponseModel?, BackendFailure>> getUser() async {
    try {
      final response = await client.get(mePath, options: Options(extra: _auth));
      final user = UserResponseModel.tryParse(response.data);
      if (user == null) return const Error(UnexpectedFailure());
      return Success(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return const Error(SessionExpiredFailure());
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() async {
    try {
      final response = await client.get(
        gestantePath,
        options: Options(extra: _auth),
      );
      final gestante = GestanteModel.tryParse(response.data);
      if (gestante == null) return const Error(UnexpectedFailure());
      return Success(gestante);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const Success(null);
      if (e.response?.statusCode == 401) return const Error(SessionExpiredFailure());
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual() async {
    try {
      final response = await client.get(
        gestacaoAtualPath,
        options: Options(extra: _auth),
      );
      final gestacao = GestacaoModel.tryParse(response.data);
      if (gestacao == null) return const Error(UnexpectedFailure());
      return Success(gestacao);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const Success(null);
      if (e.response?.statusCode == 401) return const Error(SessionExpiredFailure());
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<GestanteModel, BackendFailure>> createGestante(
    GestanteModel gestante,
  ) async {
    try {
      final response = await client.post(
        gestantePath,
        data: gestante.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = GestanteModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<GestanteModel, BackendFailure>> updateGestante(
    GestanteModel gestante,
  ) async {
    try {
      final response = await client.put(
        gestantePath,
        data: gestante.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = GestanteModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }
}
