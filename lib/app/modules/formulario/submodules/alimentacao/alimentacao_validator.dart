class AlimentacaoValidator {
  static String? refeicoesPorDia(int? value) {
    if (value == null || value <= 0) return 'Informe o número de refeições';
    return null;
  }

  static String? fonteAlimentos(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static String? avaliacaoAlimentacao(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required int refeicoesPorDia,
    required String fonteAlimentos,
    required String avaliacaoAlimentacao,
  }) {
    return refeicoesPorDia > 0 && fonteAlimentos.trim().isNotEmpty && avaliacaoAlimentacao.trim().isNotEmpty;
  }
}
