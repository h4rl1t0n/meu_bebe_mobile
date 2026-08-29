import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/plano_parto/plano_parto_model.dart';
import 'plano_parto_repository.dart';

/// Implementação HTTP do [PlanoPartoRepository] (FASE 9E).
///
/// `GET`/`PUT` sobre `/api/v1/gestacoes/{gestacao_id}/plano-de-parto`. O `PUT`
/// envia os 28 campos (full update) — nunca parcial.
class PlanoPartoRepositoryImpl implements PlanoPartoRepository {
  final DioForNative client;
  final BackendDioExceptionMapper _mapper;

  PlanoPartoRepositoryImpl({required this.client})
    : _mapper = const BackendDioExceptionMapper();

  static const _auth = {'DIO_AUTH_KEY': true};

  String _base(String gestacaoId) =>
      '/api/v1/gestacoes/$gestacaoId/plano-de-parto';

  @override
  Future<Result<PlanoPartoModel?, BackendFailure>> getPlanoParto(
    String gestacaoId,
  ) async {
    try {
      final response = await client.get(
        _base(gestacaoId),
        options: Options(extra: _auth),
      );
      final plano = PlanoPartoModel.tryParse(response.data);
      if (plano == null) return const Error(UnexpectedFailure());
      return Success(plano);
    } on DioException catch (e) {
      // Plano ainda não criado (404) → Success(null) — primeiro salvamento.
      if (e.response?.statusCode == 404) return const Success(null);
      if (e.response?.statusCode == 401) {
        return const Error(SessionExpiredFailure());
      }
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<PlanoPartoModel, BackendFailure>> upsertPlanoParto(
    String gestacaoId,
    PlanoPartoModel plano,
  ) async {
    try {
      final response = await client.put(
        _base(gestacaoId),
        data: plano.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = PlanoPartoModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }
}
