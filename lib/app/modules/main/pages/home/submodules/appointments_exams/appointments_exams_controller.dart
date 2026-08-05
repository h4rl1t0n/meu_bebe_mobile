import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/appointment.dart';
import '../../../../../../model/exam.dart';
import '../../../../../../repositories/appointments/appointments_repository.dart';
import '../../../../../../repositories/exams/exams_repository.dart';

part 'appointments_exams_controller.g.dart';

class AppointmentsExamsController = AppointmentsExamsControllerBase with _$AppointmentsExamsController;

abstract class AppointmentsExamsControllerBase with Store {
  final AppointmentsRepository appointmentsRepository;
  final ExamsRepository examsRepository;

  @observable
  bool updated = false;

  @observable
  int index = 0;

  @observable
  var appointments = ObservableList<Appointment>();

  @observable
  var exams = ObservableList<Exam>();

  Future<void> initialize() async {
    await _getAppointments();
    await _getExams();
  }

  @action
  void setIndex(int value) {
    index = value;
  }

  @action
  void resetUpdated() => updated = false;

  AppointmentsExamsControllerBase(this.appointmentsRepository, this.examsRepository);

  @action
  Future<void> _getAppointments() async {
    final result = await appointmentsRepository.getAppointments();

    switch (result) {
      case Success():
        appointments.clear();
        appointments.addAll(result.success);
        _sortAppointmentsList();
      case Error():
        Messages.showError(result.error.message);
    }
  }

  @action
  Future<void> _getExams() async {
    final result = await examsRepository.getExams();

    switch (result) {
      case Success():
        exams.clear();
        exams.addAll(result.success);
        _sortExamsList();
      case Error():
        Messages.showError(result.error.message);
    }
  }

  @action
  Future<void> saveAppointment(Appointment appointment) async {
    final result = await appointmentsRepository.saveAppointment(appointment: appointment);

    switch (result) {
      case Success():
        appointments.add(result.success);
        _sortAppointmentsList();
        updated = true;
        Messages.showSuccess('Consulta salva');
      case Error():
        Messages.showError(result.error.message);
    }
  }

  @action
  Future<void> saveExam(Exam exam) async {
    final result = await examsRepository.saveExam(exam: exam);

    switch (result) {
      case Success():
        exams.add(result.success);
        _sortExamsList();
        updated = true;
        Messages.showSuccess('Exame salvo');
      case Error():
        Messages.showError(result.error.message);
    }
  }

  @action
  Future<void> deleteAppointment(int id) async {
    final result = await appointmentsRepository.deleteAppointment(id: id);

    switch (result) {
      case Success():
        if (result.success) {
          appointments.removeWhere((appointment) => appointment.id == id);
          _sortAppointmentsList();
          updated = true;
          Messages.showSuccess('Consulta deletada');
        }
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  @action
  Future<void> deleteExam(int id) async {
    final result = await examsRepository.deleteExam(id: id);

    switch (result) {
      case Success():
        if (result.success) {
          exams.removeWhere((exam) => exam.id == id);
          _sortExamsList();
          updated = true;
          Messages.showSuccess('Exame deletado');
        }
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  @action
  void _sortAppointmentsList() {
    appointments.sort((a, b) {
      final dateA = DateTime.parse(_transformDate(a.appointmentDate));
      final dateB = DateTime.parse(_transformDate(b.appointmentDate));
      return dateA.compareTo(dateB);
    });
  }

  @action
  void _sortExamsList() {
    exams.sort((a, b) {
      final dateA = DateTime.parse(_transformDate(a.examDate));
      final dateB = DateTime.parse(_transformDate(b.examDate));
      return dateA.compareTo(dateB);
    });
  }

  String _transformDate(String date) {
    final formatted = '${date.substring(6, 10)}-${date.substring(3, 5)}-${date.substring(0, 2)}';
    return formatted;
  }
}
