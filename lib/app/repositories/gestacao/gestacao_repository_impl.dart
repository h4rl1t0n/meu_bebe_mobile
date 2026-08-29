import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/gestacao/gestacao_model.dart';
import 'gestacao_repository.dart';

/// Implementação HTTP do [GestacaoRepository] (FASE 9B).
class GestacaoRepositoryImpl implements GestacaoRepository {
  static const String gestacoesPath = '/api/v1/gestacoes';

  final DioForNative client;
  final BackendDioExceptionMapper _mapper;

  GestacaoRepositoryImpl({required this.client}) : _mapper = const BackendDioExceptionMapper();

  static const _auth = {'DIO_AUTH_KEY': true};

  @override
  Future<Result<GestacaoModel, BackendFailure>> createGestacao(GestacaoModel gestacao) async {
    try {
      final response = await client.post(
        gestacoesPath,
        data: gestacao.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = GestacaoModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      // 409 = já existe gestação ativa (índice único por gestante).
      if (e.response?.statusCode == 409) {
        return const Error(ActiveGestationExistsFailure());
      }
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<GestacaoModel, BackendFailure>> updateGestacao(GestacaoModel gestacao) async {
    try {
      final response = await client.put(
        '$gestacoesPath/${gestacao.id}',
        data: gestacao.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = GestacaoModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      // 409 = já existe gestação ativa (índice único por gestante).
      if (e.response?.statusCode == 409) {
        return const Error(ActiveGestationExistsFailure());
      }
      return Error(_mapper.map(e));
    }
  }
}
