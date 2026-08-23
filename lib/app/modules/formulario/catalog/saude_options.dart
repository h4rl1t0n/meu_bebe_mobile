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

/// Dificuldades de acesso/utilização dos serviços de saúde (múltipla escolha).
///
/// `semDificuldades` é mutuamente exclusiva: quando selecionada, as demais
/// opções são removidas (regra implementada no controller).
enum DificuldadeSaude {
  dificuldadeAgendamento('dificuldade_agendamento', 'Dificuldade para agendar'),
  demoraAtendimento('demora_atendimento', 'Demora no atendimento'),
  distancia('distancia', 'Distância'),
  faltaTransporte('falta_transporte', 'Falta de transporte'),
  horarioIncompativel('horario_incompativel', 'Horário incompatível'),
  faltaProfissional('falta_profissional', 'Falta de profissionais'),
  faltaExames('falta_exames', 'Falta de exames'),
  semDificuldades('sem_dificuldades', 'Não tenho dificuldades'),
  outro('outro', 'Outro');

  const DificuldadeSaude(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}
