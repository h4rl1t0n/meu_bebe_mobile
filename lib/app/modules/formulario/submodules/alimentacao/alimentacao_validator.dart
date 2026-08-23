import '../../catalog/alimentacao_options.dart';

class AlimentacaoValidator {
  static String? fonteAlimentos(FonteAlimentos? value) {
    if (value == null) return 'Campo obrigatório';
    return null;
  }

  static bool isTabValid({
    required RefeicoesPorDia? refeicoesPorDia,
    required FonteAlimentos? fonteAlimentos,
    required AvaliacaoAlimentacao? avaliacaoAlimentacao,
  }) {
    return refeicoesPorDia != null && fonteAlimentos != null && avaliacaoAlimentacao != null;
  }
}
