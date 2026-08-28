import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/historico_obstetrico/historico_obstetrico_model.dart';

/// Contrato do HISTÓRICO OBSTÉTRICO (1:1 com a gestante).
///
/// ``getHistorico`` retorna ``Success(null)`` quando ainda não foi preenchido
/// (404 do backend) — não é erro. ``saveHistorico`` faz upsert (PUT).
abstract class HistoricoObstetricoRepository {
  Future<Result<HistoricoObstetricoModel?, BackendFailure>> getHistorico();

  Future<Result<HistoricoObstetricoModel, BackendFailure>> saveHistorico(
    HistoricoObstetricoModel historico,
  );
}
