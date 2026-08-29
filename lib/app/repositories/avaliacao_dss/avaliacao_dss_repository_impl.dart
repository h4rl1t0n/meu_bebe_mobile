import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/avaliacao_dss/avaliacao_dss_model.dart';
import '../../modules/formulario/models/formulario_data.dart';
import 'avaliacao_dss_repository.dart';

/// Implementação HTTP do [AvaliacaoDssRepository] (FASE 9F).
///
/// Reusa o `DioForNative` compartilhado (com [AuthInterceptor] já registrado)
/// — nenhum `Dio` novo. Persiste apenas o snapshot operacional: NUNCA
/// `probability`, `risk`, `score`, classe, threshold ou recomendação (isso é
/// responsabilidade exclusiva do `/risk-estimate`, stateless).
class AvaliacaoDssRepositoryImpl implements AvaliacaoDssRepository {
  final DioForNative client;
  final BackendDioExceptionMapper _mapper;

  AvaliacaoDssRepositoryImpl({required this.client})
    : _mapper = const BackendDioExceptionMapper();

  static const _auth = {'DIO_AUTH_KEY': true};

  String _base(String gestacaoId) =>
      '/api/v1/gestacoes/$gestacaoId/avaliacoes-dss';

  @override
  Future<Result<AvaliacaoDssModel, BackendFailure>> registrar(
    String gestacaoId,
    FormularioData data,
  ) async {
    try {
      final response = await client.post(
        _base(gestacaoId),
        data: data.toMap(),
        options: Options(extra: _auth),
      );
      final parsed = AvaliacaoDssModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Error(SessionExpiredFailure());
      }
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<List<AvaliacaoDssModel>, BackendFailure>> list(
    String gestacaoId,
  ) async {
    try {
      final response = await client.get(
        _base(gestacaoId),
        options: Options(extra: _auth),
      );
      final data = response.data;
      if (data is! List) return const Error(UnexpectedFailure());

      final parsed = <AvaliacaoDssModel>[];
      for (final item in data) {
        final model = AvaliacaoDssModel.tryParse(item);
        if (model == null) return const Error(UnexpectedFailure());
        parsed.add(model);
      }
      return Success(parsed);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Error(SessionExpiredFailure());
      }
      return Error(_mapper.map(e));
    }
  }
}
