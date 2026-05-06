import 'package:mobx/mobx.dart';

part 'formulario_controller.g.dart';

class FormularioController = FormularioControllerBase with _$FormularioController;

abstract class FormularioControllerBase with Store {
  @observable
  int currentStep = 0;

  @action
  void proximo() {
    currentStep++;
  }

  @action
  void voltar() {
    currentStep--;
  }
}
