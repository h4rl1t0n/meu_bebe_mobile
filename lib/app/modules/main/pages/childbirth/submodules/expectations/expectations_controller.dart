import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/expectation.dart';
import '../../../../../../repositories/expectations/expectations_repository.dart';

part 'expectations_controller.g.dart';

class ExpectationsController = ExpectationsControllerBase with _$ExpectationsController;

abstract class ExpectationsControllerBase with Store {
  final ExpectationsRepository repository;

  @observable
  bool saved = false;

  @observable
  Expectation? expectations;

  ExpectationsControllerBase(this.repository);

  @action
  Future<void> initialize() async {
    final result = await repository.getExpectations();

    switch (result) {
      case Error():
        Messages.showError('Erro ao pegar dados das expectativas');
      case Success():
        expectations = result.success;
    }

    expectations ??= const Expectation(
      id: 0,
      companion: Alternatives.no,
      shaveIntimateHair: Alternatives.no,
      bowelWashOrSuppository: Alternatives.no,
      lowLightEnvironment: Alternatives.no,
      listenToMusic: Alternatives.no,
      drinkLiquids: Alternatives.no,
      recordPhotosOrVideos: Alternatives.no,
    );
  }

  @action
  Future<void> saveExpectations(Expectation expectations) async {
    final result = await repository.updateExpectations(expectation: expectations);

    switch (result) {
      case Error():
        Messages.showError('Erro ao salvar dados');
      case Success():
        Messages.showSuccess('Dados salvos com sucesso');
        expectations = result.success;
        saved = true;
    }
  }
}
