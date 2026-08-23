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
  bool? deixouDeComerFaltaDinheiro;

  @observable
  ObservableList<AlimentoConsumido> alimentosConsumidos = ObservableList<AlimentoConsumido>();

  @observable
  ObservableList<FonteAlimentos> fonteAlimentos = ObservableList<FonteAlimentos>();

  @observable
  bool? mudancaAlimentacaoGestacao;

  @observable
  bool? usaSuplementos;

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
  void setDeixouComerFaltaDinheiro(bool? value) {
    deixouDeComerFaltaDinheiro = value;
    validate();
  }

  @action
  void toggleAlimento(AlimentoConsumido alimento) {
    if (alimento == AlimentoConsumido.nenhumDosListados) {
      if (alimentosConsumidos.contains(alimento)) {
        alimentosConsumidos.remove(alimento);
      } else {
        alimentosConsumidos
          ..clear()
          ..add(alimento);
      }
    } else {
      alimentosConsumidos.remove(AlimentoConsumido.nenhumDosListados);
      if (alimentosConsumidos.contains(alimento)) {
        alimentosConsumidos.remove(alimento);
      } else {
        alimentosConsumidos.add(alimento);
      }
    }
    validate();
  }

  @action
  void toggleFonteAlimento(FonteAlimentos fonte) {
    if (fonteAlimentos.contains(fonte)) {
      fonteAlimentos.remove(fonte);
    } else {
      fonteAlimentos.add(fonte);
    }
    validate();
  }

  @action
  void setMudancaAlimentacaoGestacao(bool? value) {
    mudancaAlimentacaoGestacao = value;
    validate();
  }

  @action
  void setUsaSuplementos(bool? value) {
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
      deixouDeComerFaltaDinheiro: deixouDeComerFaltaDinheiro,
      alimentosConsumidos: alimentosConsumidos,
      fonteAlimentos: fonteAlimentos,
      mudancaAlimentacaoGestacao: mudancaAlimentacaoGestacao,
      usaSuplementos: usaSuplementos,
      avaliacaoAlimentacao: avaliacaoAlimentacao,
    );
  }

  AlimentacaoModel buildAlimentacaoData() => AlimentacaoModel(
    refeicoesPorDia: refeicoesPorDia?.code,
    deixouDeComerFaltaDinheiro: deixouDeComerFaltaDinheiro,
    alimentosConsumidos: alimentosConsumidos.map((a) => a.code).toList(),
    fonteAlimentos: fonteAlimentos.map((f) => f.code).toList(),
    mudancaAlimentacaoGestacao: mudancaAlimentacaoGestacao,
    usaSuplementos: usaSuplementos,
    avaliacaoAlimentacao: avaliacaoAlimentacao?.code,
  );
}
