import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/observations.dart';

abstract class ObservationsRepository {
  Future<Result<Observations?, Failure>> getObservations();
  Future<Result<Observations, Failure>> saveObservations({required Observations observations});
  Future<Result<Observations, Failure>> updateObservations({required Observations observations});
}
