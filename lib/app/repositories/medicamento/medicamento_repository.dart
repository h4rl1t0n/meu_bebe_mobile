import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/medicamento/medicamento_model.dart';

/// Contrato do domínio MEDICAMENTO (lista 1—N da gestação, FASE 9D).
///
/// O `gestacaoId` é o UUID real da gestação ativa (obtido de
/// `PerfilRepository.getGestacaoAtual`) e viaja na ROTA — nunca no payload.
abstract class MedicamentoRepository {
  Future<Result<List<MedicamentoModel>, BackendFailure>> listMedicamentos(
    String gestacaoId,
  );

  Future<Result<MedicamentoModel, BackendFailure>> createMedicamento(
    String gestacaoId,
    MedicamentoModel medicamento,
  );

  Future<Result<MedicamentoModel, BackendFailure>> updateMedicamento(
    String gestacaoId,
    MedicamentoModel medicamento,
  );

  Future<Result<bool, BackendFailure>> deleteMedicamento(
    String gestacaoId,
    String medicamentoId,
  );
}
