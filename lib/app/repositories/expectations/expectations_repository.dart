import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/expectation.dart';

abstract class ExpectationsRepository {
  Future<Result<Expectation?, Failure>> getExpectations();
  Future<Result<Expectation, Failure>> saveExpectations({required Expectation expectation});
  Future<Result<Expectation, Failure>> updateExpectations({required Expectation expectation});
}
