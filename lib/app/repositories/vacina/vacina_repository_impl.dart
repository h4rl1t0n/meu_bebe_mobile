import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/vacina/vacina_model.dart';
import 'vacina_repository.dart';

/// Implementação HTTP do [VacinaRepository] (FASE 9D).
///
/// Lista/CRUD (sem DELETE) aninhado em `/api/v1/gestacoes/{gestacao_id}/vacinas`.
/// A ordem canônica (ordem de criação) é do backend — a associação visual é por
/// `nome`, nunca por posição.
class VacinaRepositoryImpl implements VacinaRepository {
  final DioForNative client;
  final BackendDioExceptionMapper _mapper;

  VacinaRepositoryImpl({required this.client})
    : _mapper = const BackendDioExceptionMapper();

  static const _auth = {'DIO_AUTH_KEY': true};

  String _base(String gestacaoId) => '/api/v1/gestacoes/$gestacaoId/vacinas';

  @override
  Future<Result<List<VacinaModel>, BackendFailure>> listVacinas(
    String gestacaoId,
  ) async {
    try {
      final response = await client.get(
        _base(gestacaoId),
        options: Options(extra: _auth),
      );
      final raw = response.data;
      if (raw is! List) return const Error(UnexpectedFailure());
      final vacinas = raw
          .map(VacinaModel.tryParse)
          .whereType<VacinaModel>()
          .toList();
      return Success(vacinas);
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
  Future<Result<VacinaModel, BackendFailure>> createVacina(
    String gestacaoId,
    VacinaModel vacina,
  ) async {
    try {
      final response = await client.post(
        _base(gestacaoId),
        data: vacina.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = VacinaModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<VacinaModel, BackendFailure>> updateVacina(
    String gestacaoId,
    VacinaModel vacina,
  ) async {
    try {
      final response = await client.put(
        '${_base(gestacaoId)}/${vacina.id}',
        data: vacina.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = VacinaModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }
}
