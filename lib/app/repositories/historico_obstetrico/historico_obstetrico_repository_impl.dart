import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/historico_obstetrico/historico_obstetrico_model.dart';
import 'historico_obstetrico_repository.dart';

/// Implementação HTTP do [HistoricoObstetricoRepository] (FASE 9B).
class HistoricoObstetricoRepositoryImpl
    implements HistoricoObstetricoRepository {
  static const String historicoPath =
      '/api/v1/gestantes/me/historico-obstetrico';

  final DioForNative client;
  final BackendDioExceptionMapper _mapper;

  HistoricoObstetricoRepositoryImpl({required this.client})
    : _mapper = const BackendDioExceptionMapper();

  static const _auth = {'DIO_AUTH_KEY': true};

  @override
  Future<Result<HistoricoObstetricoModel?, BackendFailure>>
  getHistorico() async {
    try {
      final response = await client.get(
        historicoPath,
        options: Options(extra: _auth),
      );
      final parsed = HistoricoObstetricoModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const Success(null);
      if (e.response?.statusCode == 401) {
        return const Error(SessionExpiredFailure());
      }
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<HistoricoObstetricoModel, BackendFailure>> saveHistorico(
    HistoricoObstetricoModel historico,
  ) async {
    try {
      final response = await client.put(
        historicoPath,
        data: historico.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = HistoricoObstetricoModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }
}
