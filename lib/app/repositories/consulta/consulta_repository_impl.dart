import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/consulta/consulta_model.dart';
import 'consulta_repository.dart';

/// Implementação HTTP do [ConsultaRepository] (FASE 9C).
///
/// Lista/CRUD aninhado em `/api/v1/gestacoes/{gestacao_id}/consultas`. A
/// ordenação canônica (data ascendente) é do backend — o Flutter não reordena.
class ConsultaRepositoryImpl implements ConsultaRepository {
  final DioForNative client;
  final BackendDioExceptionMapper _mapper;

  ConsultaRepositoryImpl({required this.client})
    : _mapper = const BackendDioExceptionMapper();

  static const _auth = {'DIO_AUTH_KEY': true};

  String _base(String gestacaoId) =>
      '/api/v1/gestacoes/$gestacaoId/consultas';

  @override
  Future<Result<List<ConsultaModel>, BackendFailure>> listConsultas(
    String gestacaoId,
  ) async {
    try {
      final response = await client.get(
        _base(gestacaoId),
        options: Options(extra: _auth),
      );
      final raw = response.data;
      if (raw is! List) return const Error(UnexpectedFailure());
      final consultas = raw
          .map(ConsultaModel.tryParse)
          .whereType<ConsultaModel>()
          .toList();
      return Success(consultas);
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
  Future<Result<ConsultaModel, BackendFailure>> createConsulta(
    String gestacaoId,
    ConsultaModel consulta,
  ) async {
    try {
      final response = await client.post(
        _base(gestacaoId),
        data: consulta.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = ConsultaModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<ConsultaModel, BackendFailure>> updateConsulta(
    String gestacaoId,
    ConsultaModel consulta,
  ) async {
    try {
      final response = await client.put(
        '${_base(gestacaoId)}/${consulta.id}',
        data: consulta.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = ConsultaModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<bool, BackendFailure>> deleteConsulta(
    String gestacaoId,
    String consultaId,
  ) async {
    try {
      await client.delete(
        '${_base(gestacaoId)}/$consultaId',
        options: Options(extra: _auth),
      );
      return const Success(true);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }
}
