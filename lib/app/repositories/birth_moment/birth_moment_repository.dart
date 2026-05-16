import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/birth_moment.dart';

abstract class BirthMomentRepository {
  Future<Result<BirthMoment?, Failure>> getBirthMoment();
  Future<Result<BirthMoment, Failure>> saveBirthMoment({required BirthMoment birthMoment});
  Future<Result<BirthMoment, Failure>> updateBirthMoment({required BirthMoment birthMoment});
}
