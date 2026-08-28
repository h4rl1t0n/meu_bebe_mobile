import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/backend_failure.dart';
import '../../model/auth/auth_models.dart';

/// Contrato do repositório de autenticação contra o backend (FASE 8C).
abstract class AuthRepository {
  Future<Result<TokenResponseModel, BackendFailure>> login(
    String email,
    String password,
  );

  Future<Result<TokenResponseModel, BackendFailure>> register(
    String email,
    String password,
  );

  Future<Result<TokenResponseModel, BackendFailure>> refresh(String refreshToken);

  Future<Result<Unit, BackendFailure>> logout(String refreshToken);

  Future<Result<UserResponseModel, BackendFailure>> me();
}
