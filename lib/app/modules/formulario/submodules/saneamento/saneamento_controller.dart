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
  EsgotamentoSanitario? esgotamentoSanitario;

  @observable
  FrequenciaColetaLixo? frequenciaColetaLixo;

  @observable
  DestinoLixoSemColeta? destinoLixoSemColeta;

  @observable
  bool preocupacaoAgua = false;

  @observable
  ObservableList<CuidadoVetor> cuidadosVetores = ObservableList<CuidadoVetor>();

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
  void setEsgotamentoSanitario(EsgotamentoSanitario? value) {
    esgotamentoSanitario = value;
    validate();
  }

  @action
  void setFrequenciaColetaLixo(FrequenciaColetaLixo? value) {
    frequenciaColetaLixo = value;
    // Com coleta regular, a destinação alternativa é não aplicável.
    if (value == FrequenciaColetaLixo.regular) {
      destinoLixoSemColeta = null;
    }
    // Sem coleta, "aguardar a próxima coleta" deixa de fazer sentido.
    if (value == FrequenciaColetaLixo.naoPossui &&
        destinoLixoSemColeta == DestinoLixoSemColeta.aguardaProximaColeta) {
      destinoLixoSemColeta = null;
    }
    validate();
  }

  @action
  void setDestinoLixoSemColeta(DestinoLixoSemColeta? value) {
    destinoLixoSemColeta = value;
    validate();
  }

  @action
  void setPreocupacaoAgua(bool value) {
    preocupacaoAgua = value;
    validate();
  }

  @action
  void toggleCuidadoVetor(CuidadoVetor cuidado) {
    if (cuidado == CuidadoVetor.semCuidados) {
      // `sem_cuidados` é mutuamente exclusiva com as demais opções.
      if (cuidadosVetores.contains(CuidadoVetor.semCuidados)) {
        cuidadosVetores.clear();
      } else {
        cuidadosVetores
          ..clear()
          ..add(CuidadoVetor.semCuidados);
      }
    } else {
      // Selecionar qualquer cuidado remove `sem_cuidados`.
      cuidadosVetores.remove(CuidadoVetor.semCuidados);
      if (cuidadosVetores.contains(cuidado)) {
        cuidadosVetores.remove(cuidado);
      } else {
        cuidadosVetores.add(cuidado);
      }
    }
    validate();
  }

  @action
  void validate() {
    isValid = SaneamentoValidator.isTabValid(
      fonteAgua: fonteAgua,
      esgotamentoSanitario: esgotamentoSanitario,
      frequenciaColetaLixo: frequenciaColetaLixo,
      destinoLixoSemColeta: destinoLixoSemColeta,
    );
  }

  SaneamentoModel buildSaneamentoData() => SaneamentoModel(
    fonteAgua: fonteAgua?.code,
    interrupcoesAgua: interrupcoesAgua,
    esgotamentoSanitario: esgotamentoSanitario?.code,
    frequenciaColetaLixo: frequenciaColetaLixo?.code,
    destinoLixoSemColeta: destinoLixoSemColeta?.code,
    preocupacaoAgua: preocupacaoAgua,
    cuidadosVetores: cuidadosVetores.map((c) => c.code).toList(),
  );
}
