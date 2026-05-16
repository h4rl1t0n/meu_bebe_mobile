import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/medication.dart';

abstract class MedicationRepository {
  Future<Result<List<Medication>, Failure>> getMedications();
  Future<Result<Medication, Failure>> saveMedication({required Medication medication});
  Future<Result<bool, Failure>> deleteMedication({required int id});
}
