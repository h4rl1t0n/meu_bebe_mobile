class EducacaoValidator {
  static String? escolaridade(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({required String escolaridade}) {
    return escolaridade.trim().isNotEmpty;
  }
}
