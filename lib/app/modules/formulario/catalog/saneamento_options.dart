/// Opções canônicas da dimensão Saneamento Básico.
enum FonteAgua {
  redePublica('rede_publica', 'Rede pública'),
  pocoNascente('poco_nascente', 'Poço ou nascente'),
  cisterna('cisterna', 'Cisterna'),
  carroPipa('carro_pipa', 'Carro-pipa'),
  outra('outra', 'Outra fonte');

  const FonteAgua(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum EsgotamentoSanitario {
  redeColetora('rede_coletora', 'Rede coletora'),
  ceuAberto('ceu_aberto', 'Céu aberto/rio'),
  fossaSeptica('fossa_septica', 'Fossa séptica'),
  outro('outro', 'Outro');

  const EsgotamentoSanitario(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum ColetaLixo {
  coletaRegular('coleta_regular', 'Coleta regular'),
  coletaIrregular('coleta_irregular', 'Coleta irregular'),
  queima('queima', 'Queima do lixo'),
  terrenoBaldio('terreno_baldio', 'Joga em terreno baldio'),
  outro('outro', 'Outro método');

  const ColetaLixo(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}
