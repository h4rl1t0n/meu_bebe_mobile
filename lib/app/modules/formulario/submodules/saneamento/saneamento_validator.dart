import '../../catalog/saneamento_options.dart';

class SaneamentoValidator {
  static String? fonteAgua(FonteAgua? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? frequenciaColetaLixo(FrequenciaColetaLixo? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? destinoLixoSemColeta(DestinoLixoSemColeta? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required FonteAgua? fonteAgua,
    required EsgotamentoSanitario? esgotamentoSanitario,
    required FrequenciaColetaLixo? frequenciaColetaLixo,
    required DestinoLixoSemColeta? destinoLixoSemColeta,
  }) {
    if (fonteAgua == null || esgotamentoSanitario == null || frequenciaColetaLixo == null) {
      return false;
    }
    // Com coleta regular, a destinação alternativa é não aplicável (null).
    // Com coleta irregular ou sem coleta, a destinação é obrigatória.
    if (frequenciaColetaLixo == FrequenciaColetaLixo.regular) {
      return true;
    }
    return destinoLixoSemColeta != null;
  }
}
