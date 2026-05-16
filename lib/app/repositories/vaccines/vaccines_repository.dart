import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/vaccine_data.dart';

abstract class VaccinesRepository {
  Future<Result<List<VaccineData>, Failure>> getVaccines();
  Future<Result<VaccineData, Failure>> saveVaccine({required VaccineData vaccine});
  Future<Result<bool, Failure>> deleteVaccine({required int id});
}
