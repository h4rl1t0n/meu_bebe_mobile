import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/auth/auth_models.dart';
import '../../model/gestacao/gestacao_model.dart';
import '../../model/gestante/gestante_model.dart';

/// Contrato do repositório de perfil (usuária + gestante + gestação atual).
///
/// Fonte de verdade é o backend autenticado. Os `get*` retornam
/// `Success(null)` quando o recurso ainda não existe (404 do backend: perfil
/// de gestante ainda não criado / sem gestação ativa) — não é erro.
abstract class PerfilRepository {
  Future<Result<UserResponseModel?, BackendFailure>> getUser();

  Future<Result<GestanteModel?, BackendFailure>> getGestante();

  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual();

  Future<Result<GestanteModel, BackendFailure>> createGestante(
    GestanteModel gestante,
  );

  Future<Result<GestanteModel, BackendFailure>> updateGestante(
    GestanteModel gestante,
  );
}
