/// Opções canônicas da dimensão Saúde.
enum DistanciaUBS {
  muitoProxima('muito_proxima', 'Sim, muito próxima'),
  razoavelmenteProxima('razoavelmente_proxima', 'Sim, razoavelmente próxima'),
  distante('distante', 'Não, é distante');

  const DistanciaUBS(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum AcessoUBS {
  aPe('a_pe', 'A pé'),
  transportePublico('transporte_publico', 'Transporte público'),
  carroMoto('carro_moto', 'Carro/moto'),
  outro('outro', 'Outro');

  const AcessoUBS(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum ServicoPreNatal {
  consultaMedica('consulta_medica', 'Consulta médica regular'),
  consultaEnfermagem('consulta_enfermagem', 'Consulta com enfermeiro'),
  grupoGestantes('grupo_gestantes', 'Grupo de gestantes');

  const ServicoPreNatal(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum AvaliacaoPreNatal {
  excelente('excelente', 'Excelente'),
  bom('bom', 'Bom'),
  regular('regular', 'Regular'),
  ruim('ruim', 'Ruim'),
  pessimo('pessimo', 'Péssimo');

  const AvaliacaoPreNatal(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}
