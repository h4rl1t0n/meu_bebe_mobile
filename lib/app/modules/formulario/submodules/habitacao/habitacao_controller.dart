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
  MaterialMoradia? materialMoradia;

  @observable
  int numeroPessoas = 0;

  @observable
  int numeroComodos = 0;

  @observable
  int numeroDormitorios = 0;

  @observable
  ObservableList<ItemResidencia> itensResidencia = ObservableList<ItemResidencia>();

  @observable
  SegurancaResidencia? segurancaResidencia;

  @observable
  ObservableList<MelhoriaMoradia> melhoriasDesejadas = ObservableList<MelhoriaMoradia>();

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
  void setMaterialMoradia(MaterialMoradia? value) {
    materialMoradia = value;
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
  void setNumeroDormitorios(int value) {
    numeroDormitorios = value;
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
  void setSegurancaResidencia(SegurancaResidencia? value) {
    segurancaResidencia = value;
    validate();
  }

  @action
  void toggleMelhoriaMoradia(MelhoriaMoradia melhoria) {
    if (melhoria == MelhoriaMoradia.semMelhorias) {
      if (melhoriasDesejadas.contains(melhoria)) {
        melhoriasDesejadas.remove(melhoria);
      } else {
        melhoriasDesejadas
          ..clear()
          ..add(melhoria);
      }
    } else {
      melhoriasDesejadas.remove(MelhoriaMoradia.semMelhorias);
      if (melhoriasDesejadas.contains(melhoria)) {
        melhoriasDesejadas.remove(melhoria);
      } else {
        melhoriasDesejadas.add(melhoria);
      }
    }
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
      materialMoradia: materialMoradia,
      numeroPessoas: numeroPessoas,
      numeroComodos: numeroComodos,
      numeroDormitorios: numeroDormitorios,
      segurancaResidencia: segurancaResidencia,
    );
  }

  HabitacaoModel buildHabitacaoData() => HabitacaoModel(
    tipoMoradia: tipoMoradia?.code,
    materialMoradia: materialMoradia?.code,
    numeroPessoas: numeroPessoas,
    numeroComodos: numeroComodos,
    numeroDormitorios: numeroDormitorios,
    itensResidencia: itensResidencia.map((i) => i.code).toList(),
    segurancaResidencia: segurancaResidencia?.code,
    melhoriasDesejadas: melhoriasDesejadas.map((m) => m.code).toList(),
    facilAcessoSaude: facilAcessoSaude,
  );
}
