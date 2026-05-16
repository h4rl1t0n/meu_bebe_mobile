import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/pain_relief.dart';

abstract class PainReliefRepository {
  Future<Result<PainRelief?, Failure>> getPainRelief();
  Future<Result<PainRelief, Failure>> savePainRelief({required PainRelief painRelief});
  Future<Result<PainRelief, Failure>> updatePainRelief({required PainRelief painRelief});
}
