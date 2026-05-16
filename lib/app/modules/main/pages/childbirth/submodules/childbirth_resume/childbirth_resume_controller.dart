import 'dart:developer';

import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../model/birth.dart';
import '../../../../../../model/birth_moment.dart';
import '../../../../../../model/current_pregnancy_data.dart';
import '../../../../../../model/expectation.dart';
import '../../../../../../model/observations.dart';
import '../../../../../../model/pain_relief.dart';
import '../../../../../../model/pregnant_data.dart';
import '../../../../../../model/previous_pregnancy.dart';
import '../../../../../../repositories/birth/birth_repository.dart';
import '../../../../../../repositories/birth_moment/birth_moment_repository.dart';
import '../../../../../../repositories/current_gestation/current_gestation_repository.dart';
import '../../../../../../repositories/expectations/expectations_repository.dart';
import '../../../../../../repositories/gestation/gestation_repository.dart';
import '../../../../../../repositories/history/history_repository.dart';
import '../../../../../../repositories/observations/observations_repository.dart';
import '../../../../../../repositories/pain_relief/pain_relief_repository.dart';

part 'childbirth_resume_controller.g.dart';

class ChildbirthResumeController = ChildbirthResumeControllerBase with _$ChildbirthResumeController;

abstract class ChildbirthResumeControllerBase with Store {
  final GestationRepository gestationRepository;
  final HistoryRepository historyRepository;
  final CurrentGestationRepository currentGestationRepository;
  final ExpectationsRepository expectationsRepository;
  final BirthMomentRepository birthMomentRepository;
  final BirthRepository birthRepository;
  final PainReliefRepository painReliefRepository;
  final ObservationsRepository observationsRepository;

  ChildbirthResumeControllerBase({
    required this.gestationRepository,
    required this.historyRepository,
    required this.currentGestationRepository,
    required this.expectationsRepository,
    required this.birthMomentRepository,
    required this.birthRepository,
    required this.painReliefRepository,
    required this.observationsRepository,
  });

  @observable
  PregnantData? pregnantData;

  @observable
  PreviousPregnancy? historyData;

  @observable
  CurrentPregnancyData? currentPregnancyData;

  @observable
  Expectation? expectationsData;

  @observable
  BirthMoment? birthMomentData;

  @observable
  Birth? birthData;

  @observable
  PainRelief? painReliefData;

  @observable
  Observations? observationsData;

  @observable
  bool initialized = false;

  @observable
  bool updated = false;

  @action
  void setUpdated(bool value) => updated = value;

  @action
  Future<void> initialize() async {
    if (!initialized) {
      await Future.wait([
        getPregnant(),
        getHistory(),
        getCurrentGestation(),
        getExpectations(),
        getBirthMoment(),
        getBirth(),
        getPainRelief(),
        getObservations(),
      ]);
      initialized = true;
    }
  }

  @action
  Future<void> getPregnant() async {
    final result = await gestationRepository.getPregnant();
    switch (result) {
      case Error():
        log('Error getting pregnant data');
        pregnantData = const PregnantData(id: 0, name: '', birthDate: '', cpf: '');
      case Success():
        pregnantData = result.success;
    }
  }

  @action
  Future<void> getHistory() async {
    final result = await historyRepository.getHistory();
    switch (result) {
      case Error():
        log('Error getting history');
        historyData = const PreviousPregnancy(id: 0);
      case Success():
        historyData = result.success;
    }
  }

  @action
  Future<void> getCurrentGestation() async {
    final result = await currentGestationRepository.getGestation();
    switch (result) {
      case Error():
        log('Error getting current gestation');
        currentPregnancyData = const CurrentPregnancyData(id: 0);
      case Success():
        currentPregnancyData = result.success;
    }
  }

  @action
  Future<void> getExpectations() async {
    final result = await expectationsRepository.getExpectations();
    switch (result) {
      case Error():
        log('Error getting expectations');
      case Success():
        expectationsData = result.success;
    }
  }

  @action
  Future<void> getBirthMoment() async {
    final result = await birthMomentRepository.getBirthMoment();
    switch (result) {
      case Error():
        log('Error getting birth moment');
      case Success():
        birthMomentData = result.success;
    }
  }

  @action
  Future<void> getBirth() async {
    final result = await birthRepository.getBirth();
    switch (result) {
      case Error():
        log('Error getting birth data');
      case Success():
        birthData = result.success;
    }
  }

  @action
  Future<void> getPainRelief() async {
    final result = await painReliefRepository.getPainRelief();
    switch (result) {
      case Error():
        log('Error getting pain relief');
      case Success():
        painReliefData = result.success;
    }
  }

  @action
  Future<void> getObservations() async {
    final result = await observationsRepository.getObservations();
    switch (result) {
      case Error():
        log('Error getting observations');
      case Success():
        observationsData = result.success;
    }
  }
}
