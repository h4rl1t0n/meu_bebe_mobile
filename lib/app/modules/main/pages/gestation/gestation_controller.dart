import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../model/current_pregnancy_data.dart';
import '../../../../model/pregnant_data.dart';
import '../../../../repositories/current_gestation/current_gestation_repository.dart';
import '../../../../repositories/gestation/gestation_repository.dart';

part 'gestation_controller.g.dart';

class GestationController = GestationControllerBase with _$GestationController;

abstract class GestationControllerBase with Store {
  final GestationRepository gestationRepository;
  final CurrentGestationRepository currentGestationRepository;

  GestationControllerBase(this.gestationRepository, this.currentGestationRepository);

  @observable
  PregnantData? pregnantData;

  @observable
  CurrentPregnancyData? currentPregnancyData;

  @observable
  bool isLoading = false;

  @action
  Future<void> initialize() async {
    isLoading = true;
    await Future.wait([_getPregnant(), _getCurrentGestation()]);
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
}
