import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/exam.dart';

abstract class ExamsRepository {
  Future<Result<List<Exam>, Failure>> getExams();
  Future<Result<Exam, Failure>> saveExam({required Exam exam});
  Future<Result<bool, Failure>> deleteExam({required int id});
}
