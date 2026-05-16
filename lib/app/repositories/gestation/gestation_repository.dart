import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/pregnant_data.dart';

abstract class GestationRepository {
  Future<Result<PregnantData?, Failure>> getPregnant();
  Future<Result<PregnantData, Failure>> savePregnant({required PregnantData pregnant});
  Future<Result<PregnantData, Failure>> updatePregnant({required PregnantData pregnant});
}
