import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/avaliacao_dss/avaliacao_dss_model.dart';
import '../../modules/formulario/models/formulario_data.dart';

/// Contrato do domínio AVALIAÇÃO DSS OPERACIONAL (FASE 9F) — append-only.
///
/// Cada chamada cria um NOVO snapshot imutável do questionário, vinculado à
/// gestação autenticada. NÃO há PUT/PATCH/DELETE (preserva-se o histórico).
/// O `gestacaoId` (UUID real) viaja na ROTA — nunca no payload. O corpo é o
/// dump canônico `FormularioData.toMap()` (o MESMO usado pelo `/risk-estimate`).
abstract class AvaliacaoDssRepository {
  /// Persiste um snapshot operacional das respostas DSS em
  /// `POST /api/v1/gestacoes/{gestacao_id}/avaliacoes-dss`.
  Future<Result<AvaliacaoDssModel, BackendFailure>> registrar(
    String gestacaoId,
    FormularioData data,
  );

  /// Lista as avaliações DSS persistidas da gestação (mais recente primeiro),
  /// via `GET /api/v1/gestacoes/{gestacao_id}/avaliacoes-dss`.
  ///
  /// Retorna `Success([])` quando ainda não há nenhuma avaliação (primeiro
  /// acesso) — é a marcação de "DSS obrigatório pendente" (FASE 9G).
  Future<Result<List<AvaliacaoDssModel>, BackendFailure>> list(
    String gestacaoId,
  );
}
