import 'package:mobx/mobx.dart';

import '../../catalog/alimentacao_options.dart';
import '../../models/alimentacao/alimentacao_model.dart';
import 'alimentacao_validator.dart';

part 'alimentacao_controller.g.dart';

class AlimentacaoController = AlimentacaoControllerBase with _$AlimentacaoController;

abstract class AlimentacaoControllerBase with Store {
  @observable
  RefeicoesPorDia? refeicoesPorDia;

  @observable
  bool insegurancaAlimentar = false;

  @observable
  ObservableList<AlimentoConsumido> alimentosConsumidos = ObservableList<AlimentoConsumido>();

  @observable
  FonteAlimentos? fonteAlimentos;

  @observable
  bool mudancaAlimentacaoGestacao = false;

  @observable
  bool usaSuplementos = false;

  @observable
  AvaliacaoAlimentacao? avaliacaoAlimentacao;

  @observable
  bool isValid = false;

  @action
  void setRefeicoesPorDia(RefeicoesPorDia? value) {
    refeicoesPorDia = value;
    validate();
  }

  @action
  void setInsegurancaAlimentar(bool value) {
    insegurancaAlimentar = value;
    validate();
  }

  @action
  void toggleAlimento(AlimentoConsumido alimento) {
    if (alimentosConsumidos.contains(alimento)) {
      alimentosConsumidos.remove(alimento);
    } else {
      alimentosConsumidos.add(alimento);
    }
    validate();
  }

  @action
  void setFonteAlimentos(FonteAlimentos? value) {
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
  void setAvaliacaoAlimentacao(AvaliacaoAlimentacao? value) {
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

  AlimentacaoModel buildAlimentacaoData() => AlimentacaoModel(
    refeicoesPorDia: refeicoesPorDia?.code,
    insegurancaAlimentar: insegurancaAlimentar,
    alimentosConsumidos: alimentosConsumidos.map((a) => a.code).toList(),
    fonteAlimentos: fonteAlimentos?.code,
    mudancaAlimentacaoGestacao: mudancaAlimentacaoGestacao,
    usaSuplementos: usaSuplementos,
    avaliacaoAlimentacao: avaliacaoAlimentacao?.code,
  );
}
