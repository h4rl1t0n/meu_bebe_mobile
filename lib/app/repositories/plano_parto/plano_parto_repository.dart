import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/plano_parto/plano_parto_model.dart';

/// Contrato do domínio PLANO DE PARTO (FASE 9E) — singleton por gestação.
///
/// O recurso é 1—0..1 com a gestação: um único `GET` (404 quando ainda não
/// existe) e um único `PUT` (upsert). Não há POST, DELETE nem rota `/{id}`. O
/// `gestacaoId` (UUID real) viaja na ROTA — nunca no payload.
abstract class PlanoPartoRepository {
  /// O plano da gestação, ou `Success(null)` quando ainda não existe (404).
  Future<Result<PlanoPartoModel?, BackendFailure>> getPlanoParto(
    String gestacaoId,
  );

  /// Cria (se ausente) ou atualiza (se existente) o plano — `PUT` upsert.
  Future<Result<PlanoPartoModel, BackendFailure>> upsertPlanoParto(
    String gestacaoId,
    PlanoPartoModel plano,
  );
}
