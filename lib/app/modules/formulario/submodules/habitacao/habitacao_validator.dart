class HabitacaoValidator {
  static String? tipoMoradia(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? numeroPessoas(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    final n = int.tryParse(value);
    if (n == null || n <= 0) return 'Informe um número válido';
    return null;
  }

  static String? segurancaEstrutural(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required String tipoMoradia,
    required int numeroPessoas,
    required String segurancaEstrutural,
  }) {
    return tipoMoradia.trim().isNotEmpty && numeroPessoas > 0 && segurancaEstrutural.trim().isNotEmpty;
  }
}
