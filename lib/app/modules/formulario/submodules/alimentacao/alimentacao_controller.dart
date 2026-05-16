import 'package:mobx/mobx.dart';

import '../../models/formulario_data.dart';
import 'alimentacao_validator.dart';

part 'alimentacao_controller.g.dart';

class AlimentacaoController = AlimentacaoControllerBase with _$AlimentacaoController;

abstract class AlimentacaoControllerBase with Store {
  @observable
  int refeicoesPorDia = 0;

  @observable
  bool insegurancaAlimentar = false;

  @observable
  bool consomeFrutasVerduras = false;

  @observable
  bool consomeCarnes = false;

  @observable
  bool consomeLeite = false;

  @observable
  bool consomeFeijao = false;

  @observable
  String fonteAlimentos = '';

  @observable
  bool mudancaAlimentacaoGestacao = false;

  @observable
  bool usaSuplementos = false;

  @observable
  String avaliacaoAlimentacao = '';

  @observable
  bool isValid = false;

  @action
  void setRefeicoesPorDia(int value) {
    refeicoesPorDia = value;
    validate();
  }

  @action
  void setInsegurancaAlimentar(bool value) {
    insegurancaAlimentar = value;
    validate();
  }

  @action
  void setConsomeFrutasVerduras(bool value) {
    consomeFrutasVerduras = value;
    validate();
  }

  @action
  void setConsomeCarnes(bool value) {
    consomeCarnes = value;
    validate();
  }

  @action
  void setConsomeLeite(bool value) {
    consomeLeite = value;
    validate();
  }

  @action
  void setConsomeFeijao(bool value) {
    consomeFeijao = value;
    validate();
  }

  @action
  void setFonteAlimentos(String value) {
    fonteAlimentos = value;
    validate();
  }

  @action
  void setMudancaAlimentacaoGestacao(bool value) {
    mudancaAlimentacaoGestacao = value;
    validate();
  }

  @action
  void setUsaSuplementos(bool value) {
    usaSuplementos = value;
    validate();
  }

  @action
  void setAvaliacaoAlimentacao(String value) {
    avaliacaoAlimentacao = value;
    validate();
  }

  @action
  void validate() {
    isValid = AlimentacaoValidator.isTabValid(
      refeicoesPorDia: refeicoesPorDia,
      fonteAlimentos: fonteAlimentos,
      avaliacaoAlimentacao: avaliacaoAlimentacao,
    );
  }

  AlimentacaoData buildAlimentacaoData() => AlimentacaoData(
        refeicoesPorDia: refeicoesPorDia,
        insegurancaAlimentar: insegurancaAlimentar,
        consomeFrutasVerduras: consomeFrutasVerduras,
        consomeCarnes: consomeCarnes,
        consomeLeite: consomeLeite,
        consomeFeijao: consomeFeijao,
        fonteAlimentos: fonteAlimentos,
        mudancaAlimentacaoGestacao: mudancaAlimentacaoGestacao,
        usaSuplementos: usaSuplementos,
        avaliacaoAlimentacao: avaliacaoAlimentacao,
      );
}
