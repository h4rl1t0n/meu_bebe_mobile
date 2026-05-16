import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/previous_pregnancy.dart';

abstract class HistoryRepository {
  Future<Result<PreviousPregnancy?, Failure>> getHistory();
  Future<Result<PreviousPregnancy, Failure>> saveHistory({required PreviousPregnancy history});
  Future<Result<PreviousPregnancy, Failure>> updateHistory({required PreviousPregnancy history});
}
