import 'package:mobx/mobx.dart';

import '../../catalog/saude_options.dart';
import '../../models/saude/saude_model.dart';
import 'saude_validator.dart';

part 'saude_controller.g.dart';

class SaudeController = SaudeControllerBase with _$SaudeController;

abstract class SaudeControllerBase with Store {
  @observable
  DistanciaUBS? distanciaUBS;

  @observable
  bool faltouConsulta = false;

  @observable
  AcessoUBS? acessibilidadeUBS;

  @observable
  bool? cadastradaUBS;

  @observable
  ObservableList<ServicoPreNatal> servicosPreNatal = ObservableList<ServicoPreNatal>();

  @observable
  bool examesPreNatalCompletos = false;

  @observable
  bool vacinasEmDia = false;

  @observable
  AvaliacaoPreNatal? avaliacaoPreNatal;

  @observable
  String? dificuldadesSaude;

  @observable
  bool isValid = false;

  @action
  void setDistanciaUBS(DistanciaUBS? value) {
    distanciaUBS = value;
    validate();
  }

  @action
  void setFaltouConsulta(bool value) {
    faltouConsulta = value;
    validate();
  }

  @action
  void setAcessibilidadeUBS(AcessoUBS? value) {
    acessibilidadeUBS = value;
    if (value == null) {
      cadastradaUBS = null;
    }
    validate();
  }

  @action
  void setCadastradaUBS(bool value) {
    cadastradaUBS = value;
    validate();
  }

  @action
  void toggleServicoPreNatal(ServicoPreNatal servico) {
    if (servicosPreNatal.contains(servico)) {
      servicosPreNatal.remove(servico);
    } else {
      servicosPreNatal.add(servico);
    }
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
  void setAvaliacaoPreNatal(AvaliacaoPreNatal? value) {
    avaliacaoPreNatal = value;
    validate();
  }

  @action
  void setDificuldadesSaude(String value) {
    dificuldadesSaude = value.trim().isEmpty ? null : value;
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
    distanciaUBS: distanciaUBS?.code,
    faltouConsulta: faltouConsulta,
    acessoUBS: acessibilidadeUBS?.code,
    cadastradaUBS: acessibilidadeUBS == null ? null : cadastradaUBS,
    servicosPreNatal: servicosPreNatal.map((s) => s.code).toList(),
    examesPreNatalCompletos: examesPreNatalCompletos,
    vacinasEmDia: vacinasEmDia,
    avaliacaoPreNatal: avaliacaoPreNatal?.code,
    dificuldadesSaude: dificuldadesSaude,
  );
}
