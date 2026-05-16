import 'package:multiple_result/multiple_result.dart';

import '../../core/fp/failure.dart';
import '../../model/appointment.dart';

abstract class AppointmentsRepository {
  Future<Result<List<Appointment>, Failure>> getAppointments();
  Future<Result<Appointment, Failure>> saveAppointment({required Appointment appointment});
  Future<Result<bool, Failure>> deleteAppointment({required int id});
}
