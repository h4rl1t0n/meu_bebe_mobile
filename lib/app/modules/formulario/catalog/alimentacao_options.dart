/// Opções canônicas da dimensão Alimentação.
enum RefeicoesPorDia {
  umaDuas('uma_duas', '1-2 refeições'),
  tres('tres', '3 refeições'),
  quatroMais('quatro_mais', '4 ou mais refeições');

  const RefeicoesPorDia(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum AlimentoConsumido {
  frutasVerduras('frutas_verduras', 'Frutas e verduras'),
  carnes('carnes', 'Carnes (vermelha, frango ou peixe)'),
  leiteDerivados('leite_derivados', 'Leite e derivados'),
  feijaoLeguminosas('feijao_leguminosas', 'Feijão e outras leguminosas');

  const AlimentoConsumido(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum FonteAlimentos {
  supermercadoFeira('supermercado_feira', 'Supermercado/feira'),
  hortaPropria('horta_propria', 'Horta própria'),
  doacoes('doacoes', 'Doações'),
  cestaBasica('cesta_basica', 'Cesta básica'),
  outro('outro', 'Outro');

  const FonteAlimentos(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum AvaliacaoAlimentacao {
  muitoBoa('muito_boa', 'Muito boa - atende todas minhas necessidades'),
  boa('boa', 'Boa - com algumas limitações'),
  regular('regular', 'Regular - poderia ser melhor'),
  ruim('ruim', 'Ruim - não atende minhas necessidades');

  const AvaliacaoAlimentacao(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}
