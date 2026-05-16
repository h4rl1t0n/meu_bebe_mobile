import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/helpers/messages.dart';
import '../../repositories/gestation/gestation_repository.dart';

part 'main_controller.g.dart';

class MainController = MainControllerBase with _$MainController;

abstract class MainControllerBase with Store {
  final GestationRepository gestationRepository;

  @observable
  String name = '';

  @observable
  String tabName = 'Home';

  @action
  void setTabName(String name) => tabName = name;

  MainControllerBase(this.gestationRepository);

  @action
  Future<void> initialize() async {
    final result = await gestationRepository.getPregnant();

    switch (result) {
      case Error():
        Messages.showError('Falha ao buscar nome de usuário: ${result.error}');
      case Success():
        name = result.success?.name ?? 'Sem Nome';
    }
  }
}
