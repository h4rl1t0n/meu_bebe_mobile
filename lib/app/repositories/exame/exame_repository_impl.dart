import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/exame/exame_model.dart';
import 'exame_repository.dart';

/// Implementação HTTP do [ExameRepository] (FASE 9C).
///
/// Lista/CRUD aninhado em `/api/v1/gestacoes/{gestacao_id}/exames`. A ordenação
/// canônica (data ascendente) é do backend — o Flutter não reordena.
class ExameRepositoryImpl implements ExameRepository {
  final DioForNative client;
  final BackendDioExceptionMapper _mapper;

  ExameRepositoryImpl({required this.client})
    : _mapper = const BackendDioExceptionMapper();

  static const _auth = {'DIO_AUTH_KEY': true};

  String _base(String gestacaoId) => '/api/v1/gestacoes/$gestacaoId/exames';

  @override
  Future<Result<List<ExameModel>, BackendFailure>> listExames(
    String gestacaoId,
  ) async {
    try {
      final response = await client.get(
        _base(gestacaoId),
        options: Options(extra: _auth),
      );
      final raw = response.data;
      if (raw is! List) return const Error(UnexpectedFailure());
      final exames = raw
          .map(ExameModel.tryParse)
          .whereType<ExameModel>()
          .toList();
      return Success(exames);
    } on DioException catch (e) {
      // Gestação inexistente/alheia (404) → lista vazia (não é erro de usuário).
      if (e.response?.statusCode == 404) return const Success([]);
      if (e.response?.statusCode == 401) {
        return const Error(SessionExpiredFailure());
      }
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<ExameModel, BackendFailure>> createExame(
    String gestacaoId,
    ExameModel exame,
  ) async {
    try {
      final response = await client.post(
        _base(gestacaoId),
        data: exame.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = ExameModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<ExameModel, BackendFailure>> updateExame(
    String gestacaoId,
    ExameModel exame,
  ) async {
    try {
      final response = await client.put(
        '${_base(gestacaoId)}/${exame.id}',
        data: exame.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = ExameModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<bool, BackendFailure>> deleteExame(
    String gestacaoId,
    String exameId,
  ) async {
    try {
      await client.delete(
        '${_base(gestacaoId)}/$exameId',
        options: Options(extra: _auth),
      );
      return const Success(true);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }
}
