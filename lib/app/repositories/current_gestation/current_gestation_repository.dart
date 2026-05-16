import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/current_pregnancy_data.dart';

abstract class CurrentGestationRepository {
  Future<Result<CurrentPregnancyData?, Failure>> getGestation();
  Future<Result<CurrentPregnancyData, Failure>> saveGestation({required CurrentPregnancyData gestation});
  Future<Result<CurrentPregnancyData, Failure>> updateGestation({required CurrentPregnancyData gestation});
}
