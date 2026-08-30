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
  bool? faltouConsulta;

  @observable
  AcessoUBS? acessoUBS;

  @observable
  bool? cadastradaUBS;

  @observable
  ObservableList<ServicoPreNatal> servicosPreNatal = ObservableList<ServicoPreNatal>();

  @observable
  bool? examesPreNatalCompletos;

  @observable
  bool? vacinasEmDia;

  @observable
  AvaliacaoPreNatal? avaliacaoPreNatal;

  @observable
  ObservableList<DificuldadeSaude> dificuldadesSaude = ObservableList<DificuldadeSaude>();

  @observable
  bool isValid = false;

  /// Indica se os erros obrigatórios devem ser exibidos na aba (FASE 9G-FIX2).
  /// Acionado pelo `FormularioController` quando o usuário tenta avançar/enviar
  /// com campos obrigatórios pendentes.
  @observable
  bool showErrors = false;

  @action
  void setShowErrors(bool value) {
    showErrors = value;
  }

  @action
  void setDistanciaUBS(DistanciaUBS? value) {
    distanciaUBS = value;
    validate();
  }

  @action
  void setFaltouConsulta(bool? value) {
    faltouConsulta = value;
    validate();
  }

  @action
  void setAcessoUBS(AcessoUBS? value) {
    acessoUBS = value;
    validate();
  }

  @action
  void setCadastradaUBS(bool? value) {
    cadastradaUBS = value;
    validate();
  }

  @action
  void toggleServicoPreNatal(ServicoPreNatal servico) {
    if (servico == ServicoPreNatal.nenhumDosListados) {
      // `nenhum_dos_listados` é mutuamente exclusiva com as demais opções.
      if (servicosPreNatal.contains(ServicoPreNatal.nenhumDosListados)) {
        servicosPreNatal.clear();
      } else {
        servicosPreNatal
          ..clear()
          ..add(ServicoPreNatal.nenhumDosListados);
      }
    } else {
      // Selecionar qualquer serviço remove `nenhum_dos_listados`.
      servicosPreNatal.remove(ServicoPreNatal.nenhumDosListados);
      if (servicosPreNatal.contains(servico)) {
        servicosPreNatal.remove(servico);
      } else {
        servicosPreNatal.add(servico);
      }
    }
    validate();
  }

  @action
  void setExamesPreNatalCompletos(bool? value) {
    examesPreNatalCompletos = value;
    validate();
  }

  @action
  void setVacinasEmDia(bool? value) {
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

  /// Restaura o estado inicial para uma NOVA avaliação (FASE 9G).
  @action
  void reset() {
    distanciaUBS = null;
    faltouConsulta = null;
    acessoUBS = null;
    cadastradaUBS = null;
    servicosPreNatal.clear();
    examesPreNatalCompletos = null;
    vacinasEmDia = null;
    avaliacaoPreNatal = null;
    dificuldadesSaude.clear();
    isValid = false;
    showErrors = false;
  }

  @action
  void validate() {
    isValid = SaudeValidator.isTabValid(
      distanciaUBS: distanciaUBS,
      acessoUBS: acessoUBS,
      cadastradaUBS: cadastradaUBS,
      avaliacaoPreNatal: avaliacaoPreNatal,
      servicosPreNatal: servicosPreNatal,
      dificuldadesSaude: dificuldadesSaude,
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
