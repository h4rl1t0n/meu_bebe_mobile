import 'package:multiple_result/multiple_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/local_storage_constants.dart';
import '../core/exceptions/auth_exception.dart';
import '../core/fp/failure.dart';
import '../repositories/user/user_repository.dart';
import 'user_login_service.dart';

class UserLoginServiceImpl implements UserLoginService {
  final UserRepository userRepository;

  UserLoginServiceImpl({required this.userRepository});

  @override
  Future<Result<Unit, Failure>> execute(String email, String password) async {
    final loginResult = await userRepository.login(email, password);

    switch (loginResult) {
      case Error(error: AuthError()):
        return Error(Failure(message: 'Erro ao realizar login'));
      case Error(error: AuthUnauthorizedException()):
        return Error(Failure(message: 'Login ou senha inválidos'));
      case Success(success: final accessToken):
        final sp = await SharedPreferences.getInstance();
        await sp.setString(LocalStorageConstants.accessToken, accessToken);
        return Success(unit);
    }
  }
}
