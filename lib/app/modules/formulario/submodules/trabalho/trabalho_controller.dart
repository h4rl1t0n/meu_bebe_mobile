import 'package:mobx/mobx.dart';

import '../../models/trabalho/trabalho_model.dart';
import 'trabalho_validator.dart';

part 'trabalho_controller.g.dart';

class TrabalhoController = TrabalhoControllerBase with _$TrabalhoController;

abstract class TrabalhoControllerBase with Store {
  @observable
  bool empregado = false;

  @observable
  String tipoEmprego = '';

  @observable
  String faixaRenda = '';

  @observable
  bool permitePreNatal = false;

  @observable
  bool ambienteSeguro = false;

  @observable
  bool temPausas = false;

  @observable
  bool recebeAuxilioMaternidade = false;

  @observable
  bool recebeValeTransporte = false;

  @observable
  bool recebeValeAlimentacao = false;

  @observable
  String motivoDesemprego = '';

  @observable
  bool recebeBeneficioSocial = false;

  @observable
  String impactoGestacaoTrabalho = '';

  @observable
  bool isValid = false;

  @action
  void setEmpregado(bool value) {
    empregado = value;
    if (!value) {
      tipoEmprego = '';
      faixaRenda = '';
      permitePreNatal = false;
      ambienteSeguro = false;
      temPausas = false;
      recebeAuxilioMaternidade = false;
      recebeValeTransporte = false;
      recebeValeAlimentacao = false;
    } else {
      motivoDesemprego = '';
      recebeBeneficioSocial = false;
    }
    validate();
  }

  @action
  void setTipoEmprego(String value) {
    tipoEmprego = value;
    validate();
  }

  @action
  void setFaixaRenda(String value) {
    faixaRenda = value;
    validate();
  }

  @action
  void setPermitePreNatal(bool value) {
    permitePreNatal = value;
    validate();
  }

  @action
  void setAmbienteSeguro(bool value) {
    ambienteSeguro = value;
    validate();
  }

  @action
  void setTemPausas(bool value) {
    temPausas = value;
    validate();
  }

  @action
  void setRecebeAuxilioMaternidade(bool value) {
    recebeAuxilioMaternidade = value;
    validate();
  }

  @action
  void setRecebeValeTransporte(bool value) {
    recebeValeTransporte = value;
    validate();
  }

  @action
  void setRecebeValeAlimentacao(bool value) {
    recebeValeAlimentacao = value;
    validate();
  }

  @action
  void setMotivoDesemprego(String value) {
    motivoDesemprego = value;
    validate();
  }

  @action
  void setRecebeBeneficioSocial(bool value) {
    recebeBeneficioSocial = value;
    validate();
  }

  @action
  void setImpactoGestacaoTrabalho(String value) {
    impactoGestacaoTrabalho = value;
    validate();
  }

  @action
  void validate() {
    isValid = TrabalhoValidator.isTabValid(empregado: empregado, tipoEmprego: tipoEmprego, faixaRenda: faixaRenda);
  }

  TrabalhoModel buildTrabalhoData() {
    return TrabalhoModel(
      empregado: empregado,
      tipoEmprego: tipoEmprego,
      faixaRenda: faixaRenda,
      permitePreNatal: permitePreNatal,
      ambienteSeguro: ambienteSeguro,
      temPausas: temPausas,
      recebeAuxilioMaternidade: recebeAuxilioMaternidade,
      recebeValeTransporte: recebeValeTransporte,
      recebeValeAlimentacao: recebeValeAlimentacao,
      motivoDesemprego: motivoDesemprego,
      recebeBeneficioSocial: recebeBeneficioSocial,
      impactoGestacaoTrabalho: impactoGestacaoTrabalho,
    );
  }
}
