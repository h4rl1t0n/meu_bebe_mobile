import 'package:mobx/mobx.dart';

import '../../models/saude/saude_model.dart';
import 'saude_validator.dart';

part 'saude_controller.g.dart';

class SaudeController = SaudeControllerBase with _$SaudeController;

abstract class SaudeControllerBase with Store {
  @observable
  String distanciaUBS = '';

  @observable
  bool faltouConsulta = false;

  @observable
  String acessibilidadeUBS = '';

  @observable
  bool cadastradaUBS = false;

  @observable
  bool preNatalMedico = false;

  @observable
  bool preNatalEnfermagem = false;

  @observable
  bool participaGrupoGestantes = false;

  @observable
  bool examesPreNatalCompletos = false;

  @observable
  bool vacinasEmDia = false;

  @observable
  String avaliacaoPreNatal = '';

  @observable
  String dificuldadesSaude = '';

  @observable
  bool isValid = false;

  @action
  void setDistanciaUBS(String value) {
    distanciaUBS = value;
    validate();
  }

  @action
  void setFaltouConsulta(bool value) {
    faltouConsulta = value;
    validate();
  }

  @action
  void setAcessibilidadeUBS(String value) {
    acessibilidadeUBS = value;
    if (value.isEmpty) {
      cadastradaUBS = false;
    }
    validate();
  }

  @action
  void setCadastradaUBS(bool value) {
    cadastradaUBS = value;
    validate();
  }

  @action
  void setPreNatalMedico(bool value) {
    preNatalMedico = value;
    validate();
  }

  @action
  void setPreNatalEnfermagem(bool value) {
    preNatalEnfermagem = value;
    validate();
  }

  @action
  void setParticipaGrupoGestantes(bool value) {
    participaGrupoGestantes = value;
    validate();
  }

  @action
  void setExamesPreNatalCompletos(bool value) {
    examesPreNatalCompletos = value;
    validate();
  }

  @action
  void setVacinasEmDia(bool value) {
    vacinasEmDia = value;
    validate();
  }

  @action
  void setAvaliacaoPreNatal(String value) {
    avaliacaoPreNatal = value;
    validate();
  }

  @action
  void setDificuldadesSaude(String value) {
    dificuldadesSaude = value;
    validate();
  }

  @action
  void validate() {
    isValid = SaudeValidator.isTabValid(
      distanciaUBS: distanciaUBS,
      acessibilidadeUBS: acessibilidadeUBS,
      avaliacaoPreNatal: avaliacaoPreNatal,
    );
  }

  SaudeModel buildSaudeData() => SaudeModel(
    distanciaUBS: distanciaUBS,
    faltouConsulta: faltouConsulta,
    acessibilidadeUBS: acessibilidadeUBS,
    cadastradaUBS: cadastradaUBS,
    preNatalMedico: preNatalMedico,
    preNatalEnfermagem: preNatalEnfermagem,
    participaGrupoGestantes: participaGrupoGestantes,
    examesPreNatalCompletos: examesPreNatalCompletos,
    vacinasEmDia: vacinasEmDia,
    avaliacaoPreNatal: avaliacaoPreNatal,
    dificuldadesSaude: dificuldadesSaude,
  );
}
