class TrabalhoValidator {
  static String? tipoEmprego(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? faixaRenda(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required bool empregado,
    required String tipoEmprego,
    required String faixaRenda,
  }) {
    if (!empregado) return true;
    return tipoEmprego.trim().isNotEmpty && faixaRenda.trim().isNotEmpty;
  }
}
