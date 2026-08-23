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
  AcessoUBS? acessoUBS;

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
  ObservableList<DificuldadeSaude> dificuldadesSaude = ObservableList<DificuldadeSaude>();

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
  void setAcessoUBS(AcessoUBS? value) {
    acessoUBS = value;
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
  void toggleDificuldadeSaude(DificuldadeSaude dificuldade) {
    if (dificuldade == DificuldadeSaude.semDificuldades) {
      // `sem_dificuldades` é mutuamente exclusiva com as demais opções.
      if (dificuldadesSaude.contains(DificuldadeSaude.semDificuldades)) {
        dificuldadesSaude.clear();
      } else {
        dificuldadesSaude
          ..clear()
          ..add(DificuldadeSaude.semDificuldades);
      }
    } else {
      // Selecionar qualquer dificuldade remove `sem_dificuldades`.
      dificuldadesSaude.remove(DificuldadeSaude.semDificuldades);
      if (dificuldadesSaude.contains(dificuldade)) {
        dificuldadesSaude.remove(dificuldade);
      } else {
        dificuldadesSaude.add(dificuldade);
      }
    }
    validate();
  }

  @action
  void validate() {
    isValid = SaudeValidator.isTabValid(
      distanciaUBS: distanciaUBS,
      acessoUBS: acessoUBS,
      avaliacaoPreNatal: avaliacaoPreNatal,
    );
  }

  SaudeModel buildSaudeData() => SaudeModel(
    distanciaUBS: distanciaUBS?.code,
    faltouConsulta: faltouConsulta,
    acessoUBS: acessoUBS?.code,
    cadastradaUBS: cadastradaUBS,
    servicosPreNatal: servicosPreNatal.map((s) => s.code).toList(),
    examesPreNatalCompletos: examesPreNatalCompletos,
    vacinasEmDia: vacinasEmDia,
    avaliacaoPreNatal: avaliacaoPreNatal?.code,
    dificuldadesSaude: dificuldadesSaude.map((d) => d.code).toList(),
  );
}
