import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/consulta/consulta_model.dart';

/// Contrato do domínio CONSULTA (lista 1—N da gestação, FASE 8F).
///
/// O `gestacaoId` é o UUID real da gestação ativa (obtido de
/// `PerfilRepository.getGestacaoAtual`) e viaja na ROTA — nunca no payload.
abstract class ConsultaRepository {
  Future<Result<List<ConsultaModel>, BackendFailure>> listConsultas(
    String gestacaoId,
  );

  Future<Result<ConsultaModel, BackendFailure>> createConsulta(
    String gestacaoId,
    ConsultaModel consulta,
  );

  Future<Result<ConsultaModel, BackendFailure>> updateConsulta(
    String gestacaoId,
    ConsultaModel consulta,
  );

  Future<Result<bool, BackendFailure>> deleteConsulta(
    String gestacaoId,
    String consultaId,
  );
}
