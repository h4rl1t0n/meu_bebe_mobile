import 'package:mobx/mobx.dart';

import '../../models/saneamento/saneamento_model.dart';
import 'saneamento_validator.dart';

part 'saneamento_controller.g.dart';

class SaneamentoController = SaneamentoControllerBase with _$SaneamentoController;

abstract class SaneamentoControllerBase with Store {
  @observable
  String fonteAgua = '';

  @observable
  String interrupcoesAgua = '';

  @observable
  String destinoEsgoto = '';

  @observable
  String coletaLixo = '';

  @observable
  bool preocupacaoAgua = false;

  @observable
  String cuidadosVetores = '';

  @observable
  bool isValid = false;

  @action
  void setFonteAgua(String value) {
    fonteAgua = value;
    validate();
  }

  @action
  void setInterrupcoesAgua(String value) {
    interrupcoesAgua = value;
    validate();
  }

  @action
  void setDestinoEsgoto(String value) {
    destinoEsgoto = value;
    validate();
  }

  @action
  void setColetaLixo(String value) {
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
    cuidadosVetores = value;
    validate();
  }

  @action
  void validate() {
    isValid = SaneamentoValidator.isTabValid(
      fonteAgua: fonteAgua,
      interrupcoesAgua: interrupcoesAgua,
      destinoEsgoto: destinoEsgoto,
      coletaLixo: coletaLixo,
    );
  }

  SaneamentoModel buildSaneamentoData() => SaneamentoModel(
    fonteAgua: fonteAgua,
    interrupcoesAgua: interrupcoesAgua,
    destinoEsgoto: destinoEsgoto,
    coletaLixo: coletaLixo,
    preocupacaoAgua: preocupacaoAgua,
    cuidadosVetores: cuidadosVetores,
  );
}
