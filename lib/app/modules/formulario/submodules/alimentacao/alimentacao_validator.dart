import '../../catalog/alimentacao_options.dart';

class AlimentacaoValidator {
  /// A aba só é válida quando todas as perguntas foram respondidas: refeições,
  /// privação alimentar, grupos consumidos, fontes de alimentos, mudança na
  /// gestação, suplementos e avaliação. Booleanos `null` e listas vazias
  /// significam "não respondido" e, portanto, invalidam a aba — distinguindo
  /// "Não" (`false`) de "não informado" (`null`/vazio).
  static bool isTabValid({
    required RefeicoesPorDia? refeicoesPorDia,
    required bool? deixouDeComerFaltaDinheiro,
    required List<AlimentoConsumido> alimentosConsumidos,
    required List<FonteAlimentos> fonteAlimentos,
    required bool? mudancaAlimentacaoGestacao,
    required bool? usaSuplementos,
    required AvaliacaoAlimentacao? avaliacaoAlimentacao,
  }) {
    return refeicoesPorDia != null &&
        deixouDeComerFaltaDinheiro != null &&
        alimentosConsumidos.isNotEmpty &&
        fonteAlimentos.isNotEmpty &&
        mudancaAlimentacaoGestacao != null &&
        usaSuplementos != null &&
        avaliacaoAlimentacao != null;
  }
}
