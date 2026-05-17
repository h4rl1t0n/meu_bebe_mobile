import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../model/current_pregnancy_data.dart';
import '../../../../model/pregnant_data.dart';
import '../../../../repositories/appointments/appointments_repository.dart';
import '../../../../repositories/current_gestation/current_gestation_repository.dart';
import '../../../../repositories/exams/exams_repository.dart';
import '../../../../repositories/gestation/gestation_repository.dart';
import '../../../../repositories/history/history_repository.dart';

part 'gestation_controller.g.dart';

class GestationController = GestationControllerBase with _$GestationController;

abstract class GestationControllerBase with Store {
  final GestationRepository gestationRepository;
  final CurrentGestationRepository currentGestationRepository;
  final AppointmentsRepository appointmentsRepository;
  final ExamsRepository examsRepository;
  final HistoryRepository historyRepository;

  GestationControllerBase(
    this.gestationRepository,
    this.currentGestationRepository,
    this.appointmentsRepository,
    this.examsRepository,
    this.historyRepository,
  );

  @observable
  PregnantData? pregnantData;

  @observable
  CurrentPregnancyData? currentPregnancyData;

  @observable
  ObservableList<String> appointments = ObservableList<String>();

  @observable
  ObservableList<String> exams = ObservableList<String>();

  @observable
  ObservableList<String> historyItems = ObservableList<String>();

  @observable
  bool isLoading = false;

  @action
  Future<void> initialize() async {
    isLoading = true;
    await Future.wait([_getPregnant(), _getCurrentGestation(), _getAppointments(), _getExams(), _getHistory()]);
    isLoading = false;
  }

  @action
  Future<void> _getPregnant() async {
    final result = await gestationRepository.getPregnant();
    switch (result) {
      case Success():
        pregnantData = result.success;
      case Error():
        break;
    }
  }

  @action
  Future<void> _getCurrentGestation() async {
    final result = await currentGestationRepository.getGestation();
    switch (result) {
      case Success():
        currentPregnancyData = result.success;
      case Error():
        break;
    }
  }

  @action
  Future<void> _getAppointments() async {
    final result = await appointmentsRepository.getAppointments();
    switch (result) {
      case Success():
        appointments.clear();
        appointments.addAll(result.success.map((a) => '${a.title} - ${a.appointmentDate}'));
      case Error():
        break;
    }
  }

  @action
  Future<void> _getExams() async {
    final result = await examsRepository.getExams();
    switch (result) {
      case Success():
        exams.clear();
        exams.addAll(result.success.map((e) => '${e.title} - ${e.examDate}'));
      case Error():
        break;
    }
  }

  @action
  Future<void> _getHistory() async {
    final result = await historyRepository.getHistory();
    switch (result) {
      case Success():
        historyItems.clear();
        final h = result.success;
        if (h != null) {
          historyItems.add('Gravidezes anteriores: ${h.pregnancyNumber ?? 0}');
          historyItems.add('Partos anteriores: ${h.givenBirthNumber ?? 0}');
          historyItems.add('Abortos: ${h.abortionsNumber ?? 0}');
        }
      case Error():
        break;
    }
  }
}
