import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/birth.dart';

abstract class BirthRepository {
  Future<Result<Birth?, Failure>> getBirth();
  Future<Result<Birth, Failure>> saveBirth({required Birth birth});
  Future<Result<Birth, Failure>> updateBirth({required Birth birth});
}
