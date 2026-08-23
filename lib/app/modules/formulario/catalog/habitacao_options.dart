/// Opções canônicas da dimensão Habitação.
///
/// `tipo_moradia` (tipo/espécie de domicílio) e `material_moradia` (material
/// predominante das paredes) são eixos semânticos distintos e foram separados
/// para não misturar material (alvenaria/madeira) com tipo (casa/apartamento).
enum TipoMoradia {
  casa('casa', 'Casa'),
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

enum MaterialMoradia {
  alvenaria('alvenaria', 'Alvenaria/tijolo'),
  madeira('madeira', 'Madeira'),
  mista('mista', 'Mista'),
  outro('outro', 'Outro material');

  const MaterialMoradia(this.code, this.label);

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
  cozinhaSeparada('cozinha_separada', 'Cozinha separada'),
  nenhumDosListados('nenhum_dos_listados', 'Nenhum dos itens listados');

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

/// Percepção subjetiva da segurança da residência — NÃO é medida objetiva de
/// segurança estrutural nem de violência/segurança pública. A chave JSON é
/// `seguranca_residencia`; o rótulo reflete a percepção da gestante.
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

enum MelhoriaMoradia {
  ampliacaoEspaco('ampliacao_espaco', 'Ampliar o espaço'),
  reformaEstrutura('reforma_estrutura', 'Reforma estrutural'),
  melhorarBanheiro('melhorar_banheiro', 'Melhorar o banheiro'),
  melhorarVentilacao('melhorar_ventilacao', 'Melhorar a ventilação'),
  melhorarInstalacaoEletrica('melhorar_instalacao_eletrica', 'Melhorar a instalação elétrica'),
  melhorarAbastecimentoAgua('melhorar_abastecimento_agua', 'Melhorar o abastecimento de água'),
  melhorarSeguranca('melhorar_seguranca', 'Melhorar a segurança'),
  semMelhorias('sem_melhorias', 'Não desejo melhorias'),
  outro('outro', 'Outra melhoria');

  const MelhoriaMoradia(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}
