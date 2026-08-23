/// Opções canônicas da dimensão Habitação.
enum TipoMoradia {
  alvenaria('alvenaria', 'Casa de alvenaria'),
  madeira('madeira', 'Casa de madeira'),
  apartamento('apartamento', 'Apartamento'),
  comodoUnico('comodo_unico', 'Cômodo único'),
  outro('outro', 'Outro tipo');

  const TipoMoradia(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum ItemResidencia {
  aguaEncanada('agua_encanada', 'Água encanada'),
  banheiroInterno('banheiro_interno', 'Banheiro dentro da casa'),
  cozinhaSeparada('cozinha_separada', 'Cozinha separada');

  const ItemResidencia(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum SegurancaResidencia {
  muitoSegura('muito_segura', 'Muito segura'),
  segura('segura', 'Segura'),
  regular('regular', 'Regular'),
  insegura('insegura', 'Insegura'),
  muitoInsegura('muito_insegura', 'Muito insegura');

  const SegurancaResidencia(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}
