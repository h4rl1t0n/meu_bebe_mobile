import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/observations.dart';
import '../../../../../../repositories/observations/observations_repository.dart';

part 'observations_controller.g.dart';

class ObservationsController = ObservationsControllerBase with _$ObservationsController;

abstract class ObservationsControllerBase with Store {
  final ObservationsRepository repository;

  @observable
  bool saved = false;

  @observable
  Observations? observations;

  ObservationsControllerBase(this.repository);

  @action
  Future<void> initialize() async {
    final result = await repository.getObservations();

    switch (result) {
      case Error():
        Messages.showError('Erro ao pegar observações');
      case Success():
        observations = result.success;
    }

    observations ??= const Observations(id: 0, observations: '');
  }

  @action
  Future<void> saveObservations(Observations observations) async {
    final result = await repository.updateObservations(observations: observations);

    switch (result) {
      case Error():
        Messages.showError('Erro ao salvar dados');
      case Success():
        Messages.showSuccess('Dados salvos com sucesso');
        this.observations = result.success;
        saved = true;
    }
  }
}
