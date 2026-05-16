import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/user_data.dart';

abstract class ProfileRepository {
  Future<Result<UserData?, Failure>> getUser();
  Future<Result<UserData, Failure>> saveUser({required UserData user});
  Future<Result<UserData, Failure>> updateUser({required UserData user});
}
