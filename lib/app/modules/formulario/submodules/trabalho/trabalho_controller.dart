import 'package:mobx/mobx.dart';

import '../../catalog/trabalho_options.dart';
import '../../models/trabalho/trabalho_model.dart';
import 'trabalho_validator.dart';

part 'trabalho_controller.g.dart';

class TrabalhoController = TrabalhoControllerBase with _$TrabalhoController;

abstract class TrabalhoControllerBase with Store {
  @observable
  bool empregado = false;

  @observable
  TipoEmprego? tipoEmprego;

  @observable
  FaixaRenda? faixaRenda;

  @observable
  bool? permitePreNatal;

  @observable
  bool? ambienteSeguro;

  @observable
  bool? temPausas;

  @observable
  ObservableList<BeneficioTrabalho> beneficios = ObservableList<BeneficioTrabalho>();

  @observable
  MotivoDesemprego? motivoDesemprego;

  @observable
  bool? recebeBeneficioSocial;

  @observable
  ImpactoGestacaoTrabalho? impactoGestacaoTrabalho;

  @observable
  bool isValid = false;

  @action
  void setEmpregado(bool value) {
    empregado = value;
    if (value) {
      motivoDesemprego = null;
    } else {
      tipoEmprego = null;
      permitePreNatal = null;
      ambienteSeguro = null;
      temPausas = null;
      beneficios.clear();
    }
    validate();
  }

  @action
  void setTipoEmprego(TipoEmprego? value) {
    tipoEmprego = value;
    validate();
  }

  @action
  void setFaixaRenda(FaixaRenda? value) {
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
  void toggleBeneficio(BeneficioTrabalho beneficio) {
    if (beneficios.contains(beneficio)) {
      beneficios.remove(beneficio);
    } else {
      beneficios.add(beneficio);
    }
    validate();
  }

  @action
  void setMotivoDesemprego(MotivoDesemprego? value) {
    motivoDesemprego = value;
    validate();
  }

  @action
  void setRecebeBeneficioSocial(bool value) {
    recebeBeneficioSocial = value;
    validate();
  }

  @action
  void setImpactoGestacaoTrabalho(ImpactoGestacaoTrabalho? value) {
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
      tipoEmprego: tipoEmprego?.code,
      faixaRenda: faixaRenda?.code,
      permitePreNatal: empregado ? permitePreNatal : null,
      ambienteSeguro: empregado ? ambienteSeguro : null,
      temPausas: empregado ? temPausas : null,
      beneficiosTrabalho: empregado ? beneficios.map((b) => b.code).toList() : null,
      motivoDesemprego: motivoDesemprego?.code,
      recebeBeneficioSocial: recebeBeneficioSocial,
      impactoGestacaoTrabalho: impactoGestacaoTrabalho?.code,
    );
  }
}
