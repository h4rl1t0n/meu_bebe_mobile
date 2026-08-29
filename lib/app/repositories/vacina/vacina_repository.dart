import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/vacina/vacina_model.dart';

/// Contrato do domínio VACINA (lista 1—N da gestação, FASE 9D).
///
/// NÃO há DELETE: o Flutter não remove vacina — o checklist apenas alterna
/// `aplicada` via [updateVacina]. O `gestacaoId` é o UUID real da gestação
/// ativa e viaja na ROTA — nunca no payload.
abstract class VacinaRepository {
  Future<Result<List<VacinaModel>, BackendFailure>> listVacinas(
    String gestacaoId,
  );

  Future<Result<VacinaModel, BackendFailure>> createVacina(
    String gestacaoId,
    VacinaModel vacina,
  );

  Future<Result<VacinaModel, BackendFailure>> updateVacina(
    String gestacaoId,
    VacinaModel vacina,
  );
}
