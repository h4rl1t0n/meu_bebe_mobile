import 'package:multiple_result/multiple_result.dart';

import '../../core/exceptions/auth_exception.dart';

abstract class UserRepository {
  Future<Result<String, AuthException>> login(String email, String password);
}
