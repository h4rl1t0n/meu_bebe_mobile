import 'package:mobx/mobx.dart';

import '../../catalog/habitacao_options.dart';
import '../../models/habitacao/habitacao_model.dart';
import 'habitacao_validator.dart';

part 'habitacao_controller.g.dart';

class HabitacaoController = HabitacaoControllerBase with _$HabitacaoController;

abstract class HabitacaoControllerBase with Store {
  @observable
  TipoMoradia? tipoMoradia;

  @observable
  int numeroPessoas = 0;

  @observable
  int numeroComodos = 0;

  @observable
  ObservableList<ItemResidencia> itensResidencia = ObservableList<ItemResidencia>();

  @observable
  SegurancaResidencia? segurancaEstrutural;

  @observable
  String? melhoriasDesejadas;

  @observable
  bool facilAcessoSaude = false;

  @observable
  bool isValid = false;

  @action
  void setTipoMoradia(TipoMoradia? value) {
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
  void toggleItemResidencia(ItemResidencia item) {
    if (itensResidencia.contains(item)) {
      itensResidencia.remove(item);
    } else {
      itensResidencia.add(item);
    }
    validate();
  }

  @action
  void setSegurancaEstrutural(SegurancaResidencia? value) {
    segurancaEstrutural = value;
    validate();
  }

  @action
  void setMelhoriasDesejadas(String value) {
    melhoriasDesejadas = value.trim().isEmpty ? null : value;
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

  HabitacaoModel buildHabitacaoData() => HabitacaoModel(
    tipoMoradia: tipoMoradia?.code,
    numeroPessoas: numeroPessoas,
    numeroComodos: numeroComodos,
    itensResidencia: itensResidencia.map((i) => i.code).toList(),
    segurancaEstrutural: segurancaEstrutural?.code,
    melhoriasDesejadas: melhoriasDesejadas,
    facilAcessoSaude: facilAcessoSaude,
  );
}
