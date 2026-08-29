import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/exame/exame_model.dart';

/// Contrato do domínio EXAME (lista 1—N da gestação, FASE 8F).
///
/// O `gestacaoId` é o UUID real da gestação ativa (obtido de
/// `PerfilRepository.getGestacaoAtual`) e viaja na ROTA — nunca no payload.
abstract class ExameRepository {
  Future<Result<List<ExameModel>, BackendFailure>> listExames(
    String gestacaoId,
  );

  Future<Result<ExameModel, BackendFailure>> createExame(
    String gestacaoId,
    ExameModel exame,
  );

  Future<Result<ExameModel, BackendFailure>> updateExame(
    String gestacaoId,
    ExameModel exame,
  );

  Future<Result<bool, BackendFailure>> deleteExame(
    String gestacaoId,
    String exameId,
  );
}
