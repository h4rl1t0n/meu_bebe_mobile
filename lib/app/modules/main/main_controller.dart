import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../core/helpers/messages.dart';
import '../../repositories/gestation/gestation_repository.dart';

part 'main_controller.g.dart';

class MainController = MainControllerBase with _$MainController;

abstract class MainControllerBase with Store {
  final GestationRepository gestationRepository;

  @observable
  int index = 0;

  @observable
  String name = '';

  @observable
  String titulo = 'Home';

  @action
  void setIndex(int value) {
    index = value;
    titulo = switch (index) {
      0 => 'Home',
      1 => 'Gestação',
      2 => 'Parto',
      3 => 'Perfil',
      _ => '-',
    };
  }

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
