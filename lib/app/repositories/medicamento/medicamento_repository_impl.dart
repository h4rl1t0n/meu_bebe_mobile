import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/medicamento/medicamento_model.dart';
import 'medicamento_repository.dart';

/// Implementação HTTP do [MedicamentoRepository] (FASE 9D).
///
/// Lista/CRUD aninhado em `/api/v1/gestacoes/{gestacao_id}/medicamentos`. A
/// ordenação canônica (por nome) é do backend — o Flutter não reordena.
class MedicamentoRepositoryImpl implements MedicamentoRepository {
  final DioForNative client;
  final BackendDioExceptionMapper _mapper;

  MedicamentoRepositoryImpl({required this.client})
    : _mapper = const BackendDioExceptionMapper();

  static const _auth = {'DIO_AUTH_KEY': true};

  String _base(String gestacaoId) =>
      '/api/v1/gestacoes/$gestacaoId/medicamentos';

  @override
  Future<Result<List<MedicamentoModel>, BackendFailure>> listMedicamentos(
    String gestacaoId,
  ) async {
    try {
      final response = await client.get(
        _base(gestacaoId),
        options: Options(extra: _auth),
      );
      final raw = response.data;
      if (raw is! List) return const Error(UnexpectedFailure());
      final medicamentos = raw
          .map(MedicamentoModel.tryParse)
          .whereType<MedicamentoModel>()
          .toList();
      return Success(medicamentos);
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
  Future<Result<MedicamentoModel, BackendFailure>> createMedicamento(
    String gestacaoId,
    MedicamentoModel medicamento,
  ) async {
    try {
      final response = await client.post(
        _base(gestacaoId),
        data: medicamento.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = MedicamentoModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<MedicamentoModel, BackendFailure>> updateMedicamento(
    String gestacaoId,
    MedicamentoModel medicamento,
  ) async {
    try {
      final response = await client.put(
        '${_base(gestacaoId)}/${medicamento.id}',
        data: medicamento.toWriteJson(),
        options: Options(extra: _auth),
      );
      final parsed = MedicamentoModel.tryParse(response.data);
      if (parsed == null) return const Error(UnexpectedFailure());
      return Success(parsed);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }

  @override
  Future<Result<bool, BackendFailure>> deleteMedicamento(
    String gestacaoId,
    String medicamentoId,
  ) async {
    try {
      await client.delete(
        '${_base(gestacaoId)}/$medicamentoId',
        options: Options(extra: _auth),
      );
      return const Success(true);
    } on DioException catch (e) {
      return Error(_mapper.map(e));
    }
  }
}
