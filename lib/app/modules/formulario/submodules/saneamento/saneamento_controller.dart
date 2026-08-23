import 'package:mobx/mobx.dart';

import '../../catalog/saneamento_options.dart';
import '../../models/saneamento/saneamento_model.dart';
import 'saneamento_validator.dart';

part 'saneamento_controller.g.dart';

class SaneamentoController = SaneamentoControllerBase with _$SaneamentoController;

abstract class SaneamentoControllerBase with Store {
  @observable
  FonteAgua? fonteAgua;

  @observable
  bool interrupcoesAgua = false;

  @observable
  EsgotamentoSanitario? destinoEsgoto;

  @observable
  ColetaLixo? coletaLixo;

  @observable
  bool preocupacaoAgua = false;

  @observable
  String? cuidadosVetores;

  @observable
  bool isValid = false;

  @action
  void setFonteAgua(FonteAgua? value) {
    fonteAgua = value;
    validate();
  }

  @action
  void setInterrupcoesAgua(bool value) {
    interrupcoesAgua = value;
    validate();
  }

  @action
  void setDestinoEsgoto(EsgotamentoSanitario? value) {
    destinoEsgoto = value;
    validate();
  }

  @action
  void setColetaLixo(ColetaLixo? value) {
    coletaLixo = value;
    validate();
  }

  @action
  void setPreocupacaoAgua(bool value) {
    preocupacaoAgua = value;
    validate();
  }

  @action
  void setCuidadosVetores(String value) {
    cuidadosVetores = value.trim().isEmpty ? null : value;
    validate();
  }

  @action
  void validate() {
    isValid = SaneamentoValidator.isTabValid(
      fonteAgua: fonteAgua,
      destinoEsgoto: destinoEsgoto,
      coletaLixo: coletaLixo,
    );
  }

  SaneamentoModel buildSaneamentoData() => SaneamentoModel(
    fonteAgua: fonteAgua?.code,
    interrupcoesAgua: interrupcoesAgua,
    destinoEsgoto: destinoEsgoto?.code,
    coletaLixo: coletaLixo?.code,
    preocupacaoAgua: preocupacaoAgua,
    cuidadosVetores: cuidadosVetores,
  );
}
