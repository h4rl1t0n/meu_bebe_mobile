import 'package:mobx/mobx.dart';

import '../../models/formulario_data.dart';
import 'habitacao_validator.dart';

part 'habitacao_controller.g.dart';

class HabitacaoController = HabitacaoControllerBase with _$HabitacaoController;

abstract class HabitacaoControllerBase with Store {
  @observable
  String tipoMoradia = '';

  @observable
  int numeroPessoas = 0;

  @observable
  int numeroComodos = 0;

  @observable
  bool temAguaEncanada = false;

  @observable
  bool temBanheiro = false;

  @observable
  bool temCozinhaSeparada = false;

  @observable
  String segurancaEstrutural = '';

  @observable
  String melhoriasDesejadas = '';

  @observable
  bool facilAcessoSaude = false;

  @observable
  bool isValid = false;

  @action
  void setTipoMoradia(String value) {
    tipoMoradia = value;
    validate();
  }

  @action
  void setNumeroPessoas(int value) {
    numeroPessoas = value;
    validate();
  }

  @action
  void setNumeroComodos(int value) {
    numeroComodos = value;
    validate();
  }

  @action
  void setTemAguaEncanada(bool value) {
    temAguaEncanada = value;
    validate();
  }

  @action
  void setTemBanheiro(bool value) {
    temBanheiro = value;
    validate();
  }

  @action
  void setTemCozinhaSeparada(bool value) {
    temCozinhaSeparada = value;
    validate();
  }

  @action
  void setSegurancaEstrutural(String value) {
    segurancaEstrutural = value;
    validate();
  }

  @action
  void setMelhoriasDesejadas(String value) {
    melhoriasDesejadas = value;
    validate();
  }

  @action
  void setFacilAcessoSaude(bool value) {
    facilAcessoSaude = value;
    validate();
  }

  @action
  void validate() {
    isValid = HabitacaoValidator.isTabValid(
      tipoMoradia: tipoMoradia,
      numeroPessoas: numeroPessoas,
      segurancaEstrutural: segurancaEstrutural,
    );
  }

  HabitacaoData buildHabitacaoData() => HabitacaoData(
        tipoMoradia: tipoMoradia,
        numeroPessoas: numeroPessoas,
        numeroComodos: numeroComodos,
        temAguaEncanada: temAguaEncanada,
        temBanheiro: temBanheiro,
        temCozinhaSeparada: temCozinhaSeparada,
        segurancaEstrutural: segurancaEstrutural,
        melhoriasDesejadas: melhoriasDesejadas,
        facilAcessoSaude: facilAcessoSaude,
      );
}
