/// Opções canônicas da dimensão Trabalho e Renda.
enum TipoEmprego {
  clt('clt', 'CLT (carteira assinada)'),
  autonomo('autonomo', 'Autônoma'),
  informal('informal', 'Informal');

  const TipoEmprego(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum FaixaRenda {
  ate1Sm('ate_1_sm', 'Até 1 salário mínimo'),
  entre1e2Sm('entre_1_2_sm', '1-2 salários mínimos'),
  entre2e3Sm('entre_2_3_sm', '2-3 salários mínimos'),
  mais3Sm('mais_3_sm', 'Mais de 3 salários mínimos'),
  naoInformar('nao_informar', 'Prefiro não informar');

  const FaixaRenda(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum BeneficioTrabalho {
  auxilioMaternidade('auxilio_maternidade', 'Auxílio-maternidade'),
  valeTransporte('vale_transporte', 'Vale-transporte'),
  valeAlimentacao('vale_alimentacao', 'Vale-alimentação/refeição'),
  semBeneficios('sem_beneficios', 'Não possui os benefícios listados');

  const BeneficioTrabalho(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum MotivoDesemprego {
  dificuldadeVaga('dificuldade_encontrar_vaga', 'Dificuldade de encontrar vaga'),
  problemasSaude('problemas_saude', 'Problemas de saúde'),
  cuidadoCasaFilhos('cuidado_casa_filhos', 'Cuidando da casa/filhos'),
  gestacao('gestacao', 'Por causa da gestação'),
  opcaoPropria('opcao_propria', 'Opção própria'),
  outro('outro', 'Outro');

  const MotivoDesemprego(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum ImpactoGestacaoTrabalho {
  naoAfetou('nao_afetou', 'Não afetou'),
  reduziuJornada('reduziu_jornada', 'Reduziu minha jornada'),
  afastamentoTemporario('afastamento_temporario', 'Afastamento temporário'),
  demitida('demitida', 'Fui demitida'),
  pediuDemissao('pediu_demissao', 'Tive que pedir demissão'),
  outro('outro', 'Outro');

  const ImpactoGestacaoTrabalho(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}
