/// Opções canônicas da dimensão Educação.
///
/// Cada valor carrega o `code` (código canônico estável, usado como valor da
/// feature no dataset) e o `label` (texto apresentado ao usuário).
enum Escolaridade {
  semInstrucao('sem_instrucao', 'Sem instrução'),
  fundamentalIncompleto('fundamental_incompleto', 'Ensino Fundamental Incompleto'),
  fundamentalCompleto('fundamental_completo', 'Ensino Fundamental Completo'),
  medioIncompleto('medio_incompleto', 'Ensino Médio Incompleto'),
  medioCompleto('medio_completo', 'Ensino Médio Completo'),
  superiorIncompleto('superior_incompleto', 'Ensino Superior Incompleto'),
  superiorCompleto('superior_completo', 'Ensino Superior Completo');

  const Escolaridade(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum DificuldadeEducacao {
  faltaDinheiro('falta_dinheiro', 'Falta de dinheiro'),
  distancia('distancia', 'Distância'),
  faltaTransporte('falta_transporte', 'Falta de transporte'),
  faltaVagas('falta_vagas', 'Falta de vagas'),
  gravidez('gravidez', 'Gravidez'),
  trabalho('trabalho', 'Trabalho'),
  cuidadoFilhos('cuidado_filhos', 'Cuidados com filhos'),
  semDificuldades('sem_dificuldades', 'Não tenho dificuldades'),
  outro('outro', 'Outro');

  const DificuldadeEducacao(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

/// Situação dos estudos durante a gestação atual (substitui o antigo booleano
/// `interrompeu_estudos_gestacao`, que confundia "não estudava" com "não
/// interrompeu").
enum SituacaoEstudosGestacao {
  naoEstudava('nao_estudava', 'Não estava estudando'),
  naoInterrompeu('nao_interrompeu', 'Continuei estudando sem precisar interromper'),
  interrompeu('interrompeu', 'Precisei interromper os estudos por causa da gestação');

  const SituacaoEstudosGestacao(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}
