class SaneamentoValidator {
  static String? fonteAgua(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? interrupcoesAgua(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? destinoEsgoto(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? coletaLixo(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required String fonteAgua,
    required String interrupcoesAgua,
    required String destinoEsgoto,
    required String coletaLixo,
  }) {
    return fonteAgua.trim().isNotEmpty &&
        interrupcoesAgua.trim().isNotEmpty &&
        destinoEsgoto.trim().isNotEmpty &&
        coletaLixo.trim().isNotEmpty;
  }
}
