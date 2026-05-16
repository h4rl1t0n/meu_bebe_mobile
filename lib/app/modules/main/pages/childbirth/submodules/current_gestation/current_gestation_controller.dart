import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/current_pregnancy_data.dart';
import '../../../../../../repositories/current_gestation/current_gestation_repository.dart';

part 'current_gestation_controller.g.dart';

class CurrentGestationController = CurrentGestationControllerBase with _$CurrentGestationController;

abstract class CurrentGestationControllerBase with Store {
  final CurrentGestationRepository repository;

  @observable
  bool saved = false;

  @observable
  CurrentPregnancyData? model;

  CurrentGestationControllerBase(this.repository);

  @action
  Future<void> initialize() async {
    final result = await repository.getGestation();

    switch (result) {
      case Error():
        Messages.showError('Erro ao pegar os dados da gravidez atual');
      case Success():
        model = result.success;
    }

    model ??= const CurrentPregnancyData(id: 0);
  }

  @action
  Future<void> saveGestation(CurrentPregnancyData current) async {
    final result = await repository.updateGestation(gestation: current);

    switch (result) {
      case Error():
        Messages.showError('Erro ao salvar os dados');
      case Success():
        model = result.success;
        saved = true;
    }
  }
}
