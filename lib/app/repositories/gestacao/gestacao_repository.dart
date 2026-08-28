import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/gestacao/gestacao_model.dart';

/// Contrato de escrita do domínio GESTAÇÃO (criar/atualizar a gestação ativa).
///
/// A leitura da gestação atual reusa [PerfilRepository.getGestacaoAtual] (não
/// há uma segunda implementação de ``GET /gestacoes/atual``). Aqui ficam apenas
/// as operações de escrita: criar (POST) e atualizar (PUT).
abstract class GestacaoRepository {
  Future<Result<GestacaoModel, BackendFailure>> createGestacao(
    GestacaoModel gestacao,
  );

  Future<Result<GestacaoModel, BackendFailure>> updateGestacao(
    GestacaoModel gestacao,
  );
}
