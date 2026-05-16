import 'package:multiple_result/multiple_result.dart';

import '../core/fp/failure.dart';

abstract interface class UserLoginService {
  Future<Result<Unit, Failure>> execute(String email, String password);
}
