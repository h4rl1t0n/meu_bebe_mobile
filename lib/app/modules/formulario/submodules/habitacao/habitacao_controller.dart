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
  bool? facilAcessoSaude;

  @observable
  bool isValid = false;

  /// Indica se os erros obrigatórios devem ser exibidos na aba (FASE 9G-FIX2).
  @observable
  bool showErrors = false;

  @action
  void setShowErrors(bool value) {
    showErrors = value;
  }

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
    if (item == ItemResidencia.nenhumDosListados) {
      // `nenhum_dos_listados` é mutuamente exclusiva com as demais opções.
      if (itensResidencia.contains(ItemResidencia.nenhumDosListados)) {
        itensResidencia.clear();
      } else {
        itensResidencia
          ..clear()
          ..add(ItemResidencia.nenhumDosListados);
      }
    } else {
      // Selecionar qualquer item remove `nenhum_dos_listados`.
      itensResidencia.remove(ItemResidencia.nenhumDosListados);
      if (itensResidencia.contains(item)) {
        itensResidencia.remove(item);
      } else {
        itensResidencia.add(item);
      }
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
  void setFacilAcessoSaude(bool? value) {
    facilAcessoSaude = value;
    validate();
  }

  /// Restaura o estado inicial para uma NOVA avaliação (FASE 9G).
  @action
  void reset() {
    tipoMoradia = null;
    materialMoradia = null;
    numeroPessoas = 0;
    numeroComodos = 0;
    numeroDormitorios = 0;
    itensResidencia.clear();
    segurancaResidencia = null;
    melhoriasDesejadas.clear();
    facilAcessoSaude = null;
    isValid = false;
    showErrors = false;
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
      facilAcessoSaude: facilAcessoSaude,
      itensResidencia: itensResidencia,
      melhoriasDesejadas: melhoriasDesejadas,
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
