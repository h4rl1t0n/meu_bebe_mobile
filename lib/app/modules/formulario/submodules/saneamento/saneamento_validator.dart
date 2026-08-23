import '../../catalog/saneamento_options.dart';

class SaneamentoValidator {
  static String? fonteAgua(FonteAgua? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static String? coletaLixo(ColetaLixo? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required FonteAgua? fonteAgua,
    required EsgotamentoSanitario? destinoEsgoto,
    required ColetaLixo? coletaLixo,
  }) {
    return fonteAgua != null && destinoEsgoto != null && coletaLixo != null;
  }
}
