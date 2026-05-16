class EducacaoData {
  final String escolaridade;
  final bool estuda;
  final bool interrompeuEstudos;
  final String dificuldadesEscolares;
  final bool entendeOrientacoes;
  final String cursosExtracurriculares;
  final String expectativasEducacionais;

  const EducacaoData({
    required this.escolaridade,
    required this.estuda,
    required this.interrompeuEstudos,
    required this.dificuldadesEscolares,
    required this.entendeOrientacoes,
    required this.cursosExtracurriculares,
    required this.expectativasEducacionais,
  });

  factory EducacaoData.empty() => const EducacaoData(
    escolaridade: '',
    estuda: false,
    interrompeuEstudos: false,
    dificuldadesEscolares: '',
    entendeOrientacoes: false,
    cursosExtracurriculares: '',
    expectativasEducacionais: '',
  );

  Map<String, dynamic> toMap() => {
    'escolaridade': escolaridade,
    'estuda': estuda ? 1 : 0,
    'interrompeu_estudos': interrompeuEstudos ? 1 : 0,
    'dificuldades_escolares': dificuldadesEscolares,
    'entende_orientacoes': entendeOrientacoes ? 1 : 0,
    'cursos_extracurriculares': cursosExtracurriculares,
    'expectativas_educacionais': expectativasEducacionais,
  };

  factory EducacaoData.fromMap(Map<String, dynamic> map) => EducacaoData(
    escolaridade: map['escolaridade'] ?? '',
    estuda: (map['estuda'] ?? 0) == 1,
    interrompeuEstudos: (map['interrompeu_estudos'] ?? 0) == 1,
    dificuldadesEscolares: map['dificuldades_escolares'] ?? '',
    entendeOrientacoes: (map['entende_orientacoes'] ?? 0) == 1,
    cursosExtracurriculares: map['cursos_extracurriculares'] ?? '',
    expectativasEducacionais: map['expectativas_educacionais'] ?? '',
  );

  EducacaoData copyWith({
    String? escolaridade,
    bool? estuda,
    bool? interrompeuEstudos,
    String? dificuldadesEscolares,
    bool? entendeOrientacoes,
    String? cursosExtracurriculares,
    String? expectativasEducacionais,
  }) => EducacaoData(
    escolaridade: escolaridade ?? this.escolaridade,
    estuda: estuda ?? this.estuda,
    interrompeuEstudos: interrompeuEstudos ?? this.interrompeuEstudos,
    dificuldadesEscolares: dificuldadesEscolares ?? this.dificuldadesEscolares,
    entendeOrientacoes: entendeOrientacoes ?? this.entendeOrientacoes,
    cursosExtracurriculares: cursosExtracurriculares ?? this.cursosExtracurriculares,
    expectativasEducacionais: expectativasEducacionais ?? this.expectativasEducacionais,
  );

  @override
  String toString() =>
      'EducacaoData(escolaridade: $escolaridade, estuda: $estuda, interrompeuEstudos: $interrompeuEstudos)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducacaoData &&
          other.escolaridade == escolaridade &&
          other.estuda == estuda &&
          other.interrompeuEstudos == interrompeuEstudos &&
          other.dificuldadesEscolares == dificuldadesEscolares &&
          other.entendeOrientacoes == entendeOrientacoes &&
          other.cursosExtracurriculares == cursosExtracurriculares &&
          other.expectativasEducacionais == expectativasEducacionais;

  @override
  int get hashCode =>
      escolaridade.hashCode ^
      estuda.hashCode ^
      interrompeuEstudos.hashCode ^
      dificuldadesEscolares.hashCode ^
      entendeOrientacoes.hashCode ^
      cursosExtracurriculares.hashCode ^
      expectativasEducacionais.hashCode;
}

class TrabalhoData {
  final bool empregado;
  final String tipoEmprego;
  final String faixaRenda;
  final bool permitePreNatal;
  final bool ambienteSeguro;
  final bool temPausas;
  final bool recebeAuxilioMaternidade;
  final bool recebeValeTransporte;
  final bool recebeValeAlimentacao;
  final String motivoDesemprego;
  final bool recebeBeneficioSocial;
  final String impactoGestacaoTrabalho;

  const TrabalhoData({
    required this.empregado,
    required this.tipoEmprego,
    required this.faixaRenda,
    required this.permitePreNatal,
    required this.ambienteSeguro,
    required this.temPausas,
    required this.recebeAuxilioMaternidade,
    required this.recebeValeTransporte,
    required this.recebeValeAlimentacao,
    required this.motivoDesemprego,
    required this.recebeBeneficioSocial,
    required this.impactoGestacaoTrabalho,
  });

  factory TrabalhoData.empty() => const TrabalhoData(
    empregado: false,
    tipoEmprego: '',
    faixaRenda: '',
    permitePreNatal: false,
    ambienteSeguro: false,
    temPausas: false,
    recebeAuxilioMaternidade: false,
    recebeValeTransporte: false,
    recebeValeAlimentacao: false,
    motivoDesemprego: '',
    recebeBeneficioSocial: false,
    impactoGestacaoTrabalho: '',
  );

  Map<String, dynamic> toMap() => {
    'empregado': empregado ? 1 : 0,
    'tipo_emprego': tipoEmprego,
    'faixa_renda': faixaRenda,
    'permite_pre_natal': permitePreNatal ? 1 : 0,
    'ambiente_seguro': ambienteSeguro ? 1 : 0,
    'tem_pausas': temPausas ? 1 : 0,
    'recebe_auxilio_maternidade': recebeAuxilioMaternidade ? 1 : 0,
    'recebe_vale_transporte': recebeValeTransporte ? 1 : 0,
    'recebe_vale_alimentacao': recebeValeAlimentacao ? 1 : 0,
    'motivo_desemprego': motivoDesemprego,
    'recebe_beneficio_social': recebeBeneficioSocial ? 1 : 0,
    'impacto_gestacao_trabalho': impactoGestacaoTrabalho,
  };

  factory TrabalhoData.fromMap(Map<String, dynamic> map) => TrabalhoData(
    empregado: (map['empregado'] ?? 0) == 1,
    tipoEmprego: map['tipo_emprego'] ?? '',
    faixaRenda: map['faixa_renda'] ?? '',
    permitePreNatal: (map['permite_pre_natal'] ?? 0) == 1,
    ambienteSeguro: (map['ambiente_seguro'] ?? 0) == 1,
    temPausas: (map['tem_pausas'] ?? 0) == 1,
    recebeAuxilioMaternidade: (map['recebe_auxilio_maternidade'] ?? 0) == 1,
    recebeValeTransporte: (map['recebe_vale_transporte'] ?? 0) == 1,
    recebeValeAlimentacao: (map['recebe_vale_alimentacao'] ?? 0) == 1,
    motivoDesemprego: map['motivo_desemprego'] ?? '',
    recebeBeneficioSocial: (map['recebe_beneficio_social'] ?? 0) == 1,
    impactoGestacaoTrabalho: map['impacto_gestacao_trabalho'] ?? '',
  );

  TrabalhoData copyWith({
    bool? empregado,
    String? tipoEmprego,
    String? faixaRenda,
    bool? permitePreNatal,
    bool? ambienteSeguro,
    bool? temPausas,
    bool? recebeAuxilioMaternidade,
    bool? recebeValeTransporte,
    bool? recebeValeAlimentacao,
    String? motivoDesemprego,
    bool? recebeBeneficioSocial,
    String? impactoGestacaoTrabalho,
  }) => TrabalhoData(
    empregado: empregado ?? this.empregado,
    tipoEmprego: tipoEmprego ?? this.tipoEmprego,
    faixaRenda: faixaRenda ?? this.faixaRenda,
    permitePreNatal: permitePreNatal ?? this.permitePreNatal,
    ambienteSeguro: ambienteSeguro ?? this.ambienteSeguro,
    temPausas: temPausas ?? this.temPausas,
    recebeAuxilioMaternidade: recebeAuxilioMaternidade ?? this.recebeAuxilioMaternidade,
    recebeValeTransporte: recebeValeTransporte ?? this.recebeValeTransporte,
    recebeValeAlimentacao: recebeValeAlimentacao ?? this.recebeValeAlimentacao,
    motivoDesemprego: motivoDesemprego ?? this.motivoDesemprego,
    recebeBeneficioSocial: recebeBeneficioSocial ?? this.recebeBeneficioSocial,
    impactoGestacaoTrabalho: impactoGestacaoTrabalho ?? this.impactoGestacaoTrabalho,
  );

  @override
  String toString() => 'TrabalhoData(empregado: $empregado, tipoEmprego: $tipoEmprego, faixaRenda: $faixaRenda)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrabalhoData &&
          other.empregado == empregado &&
          other.tipoEmprego == tipoEmprego &&
          other.faixaRenda == faixaRenda &&
          other.permitePreNatal == permitePreNatal &&
          other.ambienteSeguro == ambienteSeguro &&
          other.temPausas == temPausas &&
          other.recebeAuxilioMaternidade == recebeAuxilioMaternidade &&
          other.recebeValeTransporte == recebeValeTransporte &&
          other.recebeValeAlimentacao == recebeValeAlimentacao &&
          other.motivoDesemprego == motivoDesemprego &&
          other.recebeBeneficioSocial == recebeBeneficioSocial &&
          other.impactoGestacaoTrabalho == impactoGestacaoTrabalho;

  @override
  int get hashCode =>
      empregado.hashCode ^
      tipoEmprego.hashCode ^
      faixaRenda.hashCode ^
      permitePreNatal.hashCode ^
      ambienteSeguro.hashCode ^
      temPausas.hashCode ^
      recebeAuxilioMaternidade.hashCode ^
      recebeValeTransporte.hashCode ^
      recebeValeAlimentacao.hashCode ^
      motivoDesemprego.hashCode ^
      recebeBeneficioSocial.hashCode ^
      impactoGestacaoTrabalho.hashCode;
}

class SaneamentoData {
  final String fonteAgua;
  final String interrupcoesAgua;
  final String destinoEsgoto;
  final String coletaLixo;
  final bool preocupacaoAgua;
  final String cuidadosVetores;

  const SaneamentoData({
    required this.fonteAgua,
    required this.interrupcoesAgua,
    required this.destinoEsgoto,
    required this.coletaLixo,
    required this.preocupacaoAgua,
    required this.cuidadosVetores,
  });

  factory SaneamentoData.empty() => const SaneamentoData(
    fonteAgua: '',
    interrupcoesAgua: '',
    destinoEsgoto: '',
    coletaLixo: '',
    preocupacaoAgua: false,
    cuidadosVetores: '',
  );

  Map<String, dynamic> toMap() => {
    'fonte_agua': fonteAgua,
    'interrupcoes_agua': interrupcoesAgua,
    'destino_esgoto': destinoEsgoto,
    'coleta_lixo': coletaLixo,
    'preocupacao_agua': preocupacaoAgua ? 1 : 0,
    'cuidados_vetores': cuidadosVetores,
  };

  factory SaneamentoData.fromMap(Map<String, dynamic> map) => SaneamentoData(
    fonteAgua: map['fonte_agua'] ?? '',
    interrupcoesAgua: map['interrupcoes_agua'] ?? '',
    destinoEsgoto: map['destino_esgoto'] ?? '',
    coletaLixo: map['coleta_lixo'] ?? '',
    preocupacaoAgua: (map['preocupacao_agua'] ?? 0) == 1,
    cuidadosVetores: map['cuidados_vetores'] ?? '',
  );

  SaneamentoData copyWith({
    String? fonteAgua,
    String? interrupcoesAgua,
    String? destinoEsgoto,
    String? coletaLixo,
    bool? preocupacaoAgua,
    String? cuidadosVetores,
  }) => SaneamentoData(
    fonteAgua: fonteAgua ?? this.fonteAgua,
    interrupcoesAgua: interrupcoesAgua ?? this.interrupcoesAgua,
    destinoEsgoto: destinoEsgoto ?? this.destinoEsgoto,
    coletaLixo: coletaLixo ?? this.coletaLixo,
    preocupacaoAgua: preocupacaoAgua ?? this.preocupacaoAgua,
    cuidadosVetores: cuidadosVetores ?? this.cuidadosVetores,
  );

  @override
  String toString() => 'SaneamentoData(fonteAgua: $fonteAgua, destinoEsgoto: $destinoEsgoto, coletaLixo: $coletaLixo)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaneamentoData &&
          other.fonteAgua == fonteAgua &&
          other.interrupcoesAgua == interrupcoesAgua &&
          other.destinoEsgoto == destinoEsgoto &&
          other.coletaLixo == coletaLixo &&
          other.preocupacaoAgua == preocupacaoAgua &&
          other.cuidadosVetores == cuidadosVetores;

  @override
  int get hashCode =>
      fonteAgua.hashCode ^
      interrupcoesAgua.hashCode ^
      destinoEsgoto.hashCode ^
      coletaLixo.hashCode ^
      preocupacaoAgua.hashCode ^
      cuidadosVetores.hashCode;
}

class SaudeData {
  final String distanciaUBS;
  final bool faltouConsulta;
  final String acessibilidadeUBS;
  final bool cadastradaUBS;
  final bool preNatalMedico;
  final bool preNatalEnfermagem;
  final bool participaGrupoGestantes;
  final bool examesPreNatalCompletos;
  final bool vacinasEmDia;
  final String avaliacaoPreNatal;
  final String dificuldadesSaude;

  const SaudeData({
    required this.distanciaUBS,
    required this.faltouConsulta,
    required this.acessibilidadeUBS,
    required this.cadastradaUBS,
    required this.preNatalMedico,
    required this.preNatalEnfermagem,
    required this.participaGrupoGestantes,
    required this.examesPreNatalCompletos,
    required this.vacinasEmDia,
    required this.avaliacaoPreNatal,
    required this.dificuldadesSaude,
  });

  factory SaudeData.empty() => const SaudeData(
    distanciaUBS: '',
    faltouConsulta: false,
    acessibilidadeUBS: '',
    cadastradaUBS: false,
    preNatalMedico: false,
    preNatalEnfermagem: false,
    participaGrupoGestantes: false,
    examesPreNatalCompletos: false,
    vacinasEmDia: false,
    avaliacaoPreNatal: '',
    dificuldadesSaude: '',
  );

  Map<String, dynamic> toMap() => {
    'distancia_ubs': distanciaUBS,
    'faltou_consulta': faltouConsulta ? 1 : 0,
    'acessibilidade_ubs': acessibilidadeUBS,
    'cadastrada_ubs': cadastradaUBS ? 1 : 0,
    'pre_natal_medico': preNatalMedico ? 1 : 0,
    'pre_natal_enfermagem': preNatalEnfermagem ? 1 : 0,
    'participa_grupo_gestantes': participaGrupoGestantes ? 1 : 0,
    'exames_pre_natal_completos': examesPreNatalCompletos ? 1 : 0,
    'vacinas_em_dia': vacinasEmDia ? 1 : 0,
    'avaliacao_pre_natal': avaliacaoPreNatal,
    'dificuldades_saude': dificuldadesSaude,
  };

  factory SaudeData.fromMap(Map<String, dynamic> map) => SaudeData(
    distanciaUBS: map['distancia_ubs'] ?? '',
    faltouConsulta: (map['faltou_consulta'] ?? 0) == 1,
    acessibilidadeUBS: map['acessibilidade_ubs'] ?? '',
    cadastradaUBS: (map['cadastrada_ubs'] ?? 0) == 1,
    preNatalMedico: (map['pre_natal_medico'] ?? 0) == 1,
    preNatalEnfermagem: (map['pre_natal_enfermagem'] ?? 0) == 1,
    participaGrupoGestantes: (map['participa_grupo_gestantes'] ?? 0) == 1,
    examesPreNatalCompletos: (map['exames_pre_natal_completos'] ?? 0) == 1,
    vacinasEmDia: (map['vacinas_em_dia'] ?? 0) == 1,
    avaliacaoPreNatal: map['avaliacao_pre_natal'] ?? '',
    dificuldadesSaude: map['dificuldades_saude'] ?? '',
  );

  SaudeData copyWith({
    String? distanciaUBS,
    bool? faltouConsulta,
    String? acessibilidadeUBS,
    bool? cadastradaUBS,
    bool? preNatalMedico,
    bool? preNatalEnfermagem,
    bool? participaGrupoGestantes,
    bool? examesPreNatalCompletos,
    bool? vacinasEmDia,
    String? avaliacaoPreNatal,
    String? dificuldadesSaude,
  }) => SaudeData(
    distanciaUBS: distanciaUBS ?? this.distanciaUBS,
    faltouConsulta: faltouConsulta ?? this.faltouConsulta,
    acessibilidadeUBS: acessibilidadeUBS ?? this.acessibilidadeUBS,
    cadastradaUBS: cadastradaUBS ?? this.cadastradaUBS,
    preNatalMedico: preNatalMedico ?? this.preNatalMedico,
    preNatalEnfermagem: preNatalEnfermagem ?? this.preNatalEnfermagem,
    participaGrupoGestantes: participaGrupoGestantes ?? this.participaGrupoGestantes,
    examesPreNatalCompletos: examesPreNatalCompletos ?? this.examesPreNatalCompletos,
    vacinasEmDia: vacinasEmDia ?? this.vacinasEmDia,
    avaliacaoPreNatal: avaliacaoPreNatal ?? this.avaliacaoPreNatal,
    dificuldadesSaude: dificuldadesSaude ?? this.dificuldadesSaude,
  );

  @override
  String toString() =>
      'SaudeData(distanciaUBS: $distanciaUBS, cadastradaUBS: $cadastradaUBS, avaliacaoPreNatal: $avaliacaoPreNatal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaudeData &&
          other.distanciaUBS == distanciaUBS &&
          other.faltouConsulta == faltouConsulta &&
          other.acessibilidadeUBS == acessibilidadeUBS &&
          other.cadastradaUBS == cadastradaUBS &&
          other.preNatalMedico == preNatalMedico &&
          other.preNatalEnfermagem == preNatalEnfermagem &&
          other.participaGrupoGestantes == participaGrupoGestantes &&
          other.examesPreNatalCompletos == examesPreNatalCompletos &&
          other.vacinasEmDia == vacinasEmDia &&
          other.avaliacaoPreNatal == avaliacaoPreNatal &&
          other.dificuldadesSaude == dificuldadesSaude;

  @override
  int get hashCode =>
      distanciaUBS.hashCode ^
      faltouConsulta.hashCode ^
      acessibilidadeUBS.hashCode ^
      cadastradaUBS.hashCode ^
      preNatalMedico.hashCode ^
      preNatalEnfermagem.hashCode ^
      participaGrupoGestantes.hashCode ^
      examesPreNatalCompletos.hashCode ^
      vacinasEmDia.hashCode ^
      avaliacaoPreNatal.hashCode ^
      dificuldadesSaude.hashCode;
}

class HabitacaoData {
  final String tipoMoradia;
  final int numeroPessoas;
  final int numeroComodos;
  final bool temAguaEncanada;
  final bool temBanheiro;
  final bool temCozinhaSeparada;
  final String segurancaEstrutural;
  final String melhoriasDesejadas;
  final bool facilAcessoSaude;

  const HabitacaoData({
    required this.tipoMoradia,
    required this.numeroPessoas,
    required this.numeroComodos,
    required this.temAguaEncanada,
    required this.temBanheiro,
    required this.temCozinhaSeparada,
    required this.segurancaEstrutural,
    required this.melhoriasDesejadas,
    required this.facilAcessoSaude,
  });

  factory HabitacaoData.empty() => const HabitacaoData(
    tipoMoradia: '',
    numeroPessoas: 0,
    numeroComodos: 0,
    temAguaEncanada: false,
    temBanheiro: false,
    temCozinhaSeparada: false,
    segurancaEstrutural: '',
    melhoriasDesejadas: '',
    facilAcessoSaude: false,
  );

  Map<String, dynamic> toMap() => {
    'tipo_moradia': tipoMoradia,
    'numero_pessoas': numeroPessoas,
    'numero_comodos': numeroComodos,
    'tem_agua_encanada': temAguaEncanada ? 1 : 0,
    'tem_banheiro': temBanheiro ? 1 : 0,
    'tem_cozinha_separada': temCozinhaSeparada ? 1 : 0,
    'seguranca_estrutural': segurancaEstrutural,
    'melhorias_desejadas': melhoriasDesejadas,
    'facil_acesso_saude': facilAcessoSaude ? 1 : 0,
  };

  factory HabitacaoData.fromMap(Map<String, dynamic> map) => HabitacaoData(
    tipoMoradia: map['tipo_moradia'] ?? '',
    numeroPessoas: map['numero_pessoas'] ?? 0,
    numeroComodos: map['numero_comodos'] ?? 0,
    temAguaEncanada: (map['tem_agua_encanada'] ?? 0) == 1,
    temBanheiro: (map['tem_banheiro'] ?? 0) == 1,
    temCozinhaSeparada: (map['tem_cozinha_separada'] ?? 0) == 1,
    segurancaEstrutural: map['seguranca_estrutural'] ?? '',
    melhoriasDesejadas: map['melhorias_desejadas'] ?? '',
    facilAcessoSaude: (map['facil_acesso_saude'] ?? 0) == 1,
  );

  HabitacaoData copyWith({
    String? tipoMoradia,
    int? numeroPessoas,
    int? numeroComodos,
    bool? temAguaEncanada,
    bool? temBanheiro,
    bool? temCozinhaSeparada,
    String? segurancaEstrutural,
    String? melhoriasDesejadas,
    bool? facilAcessoSaude,
  }) => HabitacaoData(
    tipoMoradia: tipoMoradia ?? this.tipoMoradia,
    numeroPessoas: numeroPessoas ?? this.numeroPessoas,
    numeroComodos: numeroComodos ?? this.numeroComodos,
    temAguaEncanada: temAguaEncanada ?? this.temAguaEncanada,
    temBanheiro: temBanheiro ?? this.temBanheiro,
    temCozinhaSeparada: temCozinhaSeparada ?? this.temCozinhaSeparada,
    segurancaEstrutural: segurancaEstrutural ?? this.segurancaEstrutural,
    melhoriasDesejadas: melhoriasDesejadas ?? this.melhoriasDesejadas,
    facilAcessoSaude: facilAcessoSaude ?? this.facilAcessoSaude,
  );

  @override
  String toString() =>
      'HabitacaoData(tipoMoradia: $tipoMoradia, numeroPessoas: $numeroPessoas, numeroComodos: $numeroComodos)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitacaoData &&
          other.tipoMoradia == tipoMoradia &&
          other.numeroPessoas == numeroPessoas &&
          other.numeroComodos == numeroComodos &&
          other.temAguaEncanada == temAguaEncanada &&
          other.temBanheiro == temBanheiro &&
          other.temCozinhaSeparada == temCozinhaSeparada &&
          other.segurancaEstrutural == segurancaEstrutural &&
          other.melhoriasDesejadas == melhoriasDesejadas &&
          other.facilAcessoSaude == facilAcessoSaude;

  @override
  int get hashCode =>
      tipoMoradia.hashCode ^
      numeroPessoas.hashCode ^
      numeroComodos.hashCode ^
      temAguaEncanada.hashCode ^
      temBanheiro.hashCode ^
      temCozinhaSeparada.hashCode ^
      segurancaEstrutural.hashCode ^
      melhoriasDesejadas.hashCode ^
      facilAcessoSaude.hashCode;
}

class AlimentacaoData {
  final int refeicoesPorDia;
  final bool insegurancaAlimentar;
  final bool consomeFrutasVerduras;
  final bool consomeCarnes;
  final bool consomeLeite;
  final bool consomeFeijao;
  final String fonteAlimentos;
  final bool mudancaAlimentacaoGestacao;
  final bool usaSuplementos;
  final String avaliacaoAlimentacao;

  const AlimentacaoData({
    required this.refeicoesPorDia,
    required this.insegurancaAlimentar,
    required this.consomeFrutasVerduras,
    required this.consomeCarnes,
    required this.consomeLeite,
    required this.consomeFeijao,
    required this.fonteAlimentos,
    required this.mudancaAlimentacaoGestacao,
    required this.usaSuplementos,
    required this.avaliacaoAlimentacao,
  });

  factory AlimentacaoData.empty() => const AlimentacaoData(
    refeicoesPorDia: 0,
    insegurancaAlimentar: false,
    consomeFrutasVerduras: false,
    consomeCarnes: false,
    consomeLeite: false,
    consomeFeijao: false,
    fonteAlimentos: '',
    mudancaAlimentacaoGestacao: false,
    usaSuplementos: false,
    avaliacaoAlimentacao: '',
  );

  Map<String, dynamic> toMap() => {
    'refeicoes_por_dia': refeicoesPorDia,
    'inseguranca_alimentar': insegurancaAlimentar ? 1 : 0,
    'consome_frutas_verduras': consomeFrutasVerduras ? 1 : 0,
    'consome_carnes': consomeCarnes ? 1 : 0,
    'consome_leite': consomeLeite ? 1 : 0,
    'consome_feijao': consomeFeijao ? 1 : 0,
    'fonte_alimentos': fonteAlimentos,
    'mudanca_alimentacao_gestacao': mudancaAlimentacaoGestacao ? 1 : 0,
    'usa_suplementos': usaSuplementos ? 1 : 0,
    'avaliacao_alimentacao': avaliacaoAlimentacao,
  };

  factory AlimentacaoData.fromMap(Map<String, dynamic> map) => AlimentacaoData(
    refeicoesPorDia: map['refeicoes_por_dia'] ?? 0,
    insegurancaAlimentar: (map['inseguranca_alimentar'] ?? 0) == 1,
    consomeFrutasVerduras: (map['consome_frutas_verduras'] ?? 0) == 1,
    consomeCarnes: (map['consome_carnes'] ?? 0) == 1,
    consomeLeite: (map['consome_leite'] ?? 0) == 1,
    consomeFeijao: (map['consome_feijao'] ?? 0) == 1,
    fonteAlimentos: map['fonte_alimentos'] ?? '',
    mudancaAlimentacaoGestacao: (map['mudanca_alimentacao_gestacao'] ?? 0) == 1,
    usaSuplementos: (map['usa_suplementos'] ?? 0) == 1,
    avaliacaoAlimentacao: map['avaliacao_alimentacao'] ?? '',
  );

  AlimentacaoData copyWith({
    int? refeicoesPorDia,
    bool? insegurancaAlimentar,
    bool? consomeFrutasVerduras,
    bool? consomeCarnes,
    bool? consomeLeite,
    bool? consomeFeijao,
    String? fonteAlimentos,
    bool? mudancaAlimentacaoGestacao,
    bool? usaSuplementos,
    String? avaliacaoAlimentacao,
  }) => AlimentacaoData(
    refeicoesPorDia: refeicoesPorDia ?? this.refeicoesPorDia,
    insegurancaAlimentar: insegurancaAlimentar ?? this.insegurancaAlimentar,
    consomeFrutasVerduras: consomeFrutasVerduras ?? this.consomeFrutasVerduras,
    consomeCarnes: consomeCarnes ?? this.consomeCarnes,
    consomeLeite: consomeLeite ?? this.consomeLeite,
    consomeFeijao: consomeFeijao ?? this.consomeFeijao,
    fonteAlimentos: fonteAlimentos ?? this.fonteAlimentos,
    mudancaAlimentacaoGestacao: mudancaAlimentacaoGestacao ?? this.mudancaAlimentacaoGestacao,
    usaSuplementos: usaSuplementos ?? this.usaSuplementos,
    avaliacaoAlimentacao: avaliacaoAlimentacao ?? this.avaliacaoAlimentacao,
  );

  @override
  String toString() =>
      'AlimentacaoData(refeicoesPorDia: $refeicoesPorDia, insegurancaAlimentar: $insegurancaAlimentar)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlimentacaoData &&
          other.refeicoesPorDia == refeicoesPorDia &&
          other.insegurancaAlimentar == insegurancaAlimentar &&
          other.consomeFrutasVerduras == consomeFrutasVerduras &&
          other.consomeCarnes == consomeCarnes &&
          other.consomeLeite == consomeLeite &&
          other.consomeFeijao == consomeFeijao &&
          other.fonteAlimentos == fonteAlimentos &&
          other.mudancaAlimentacaoGestacao == mudancaAlimentacaoGestacao &&
          other.usaSuplementos == usaSuplementos &&
          other.avaliacaoAlimentacao == avaliacaoAlimentacao;

  @override
  int get hashCode =>
      refeicoesPorDia.hashCode ^
      insegurancaAlimentar.hashCode ^
      consomeFrutasVerduras.hashCode ^
      consomeCarnes.hashCode ^
      consomeLeite.hashCode ^
      consomeFeijao.hashCode ^
      fonteAlimentos.hashCode ^
      mudancaAlimentacaoGestacao.hashCode ^
      usaSuplementos.hashCode ^
      avaliacaoAlimentacao.hashCode;
}

class FormularioData {
  final EducacaoData educacao;
  final TrabalhoData trabalho;
  final SaneamentoData saneamento;
  final SaudeData saude;
  final HabitacaoData habitacao;
  final AlimentacaoData alimentacao;

  const FormularioData({
    required this.educacao,
    required this.trabalho,
    required this.saneamento,
    required this.saude,
    required this.habitacao,
    required this.alimentacao,
  });

  factory FormularioData.empty() => FormularioData(
    educacao: EducacaoData.empty(),
    trabalho: TrabalhoData.empty(),
    saneamento: SaneamentoData.empty(),
    saude: SaudeData.empty(),
    habitacao: HabitacaoData.empty(),
    alimentacao: AlimentacaoData.empty(),
  );

  Map<String, dynamic> toMap() => {
    ...educacao.toMap(),
    ...trabalho.toMap(),
    ...saneamento.toMap(),
    ...saude.toMap(),
    ...habitacao.toMap(),
    ...alimentacao.toMap(),
  };

  factory FormularioData.fromMap(Map<String, dynamic> map) => FormularioData(
    educacao: EducacaoData.fromMap(map),
    trabalho: TrabalhoData.fromMap(map),
    saneamento: SaneamentoData.fromMap(map),
    saude: SaudeData.fromMap(map),
    habitacao: HabitacaoData.fromMap(map),
    alimentacao: AlimentacaoData.fromMap(map),
  );

  FormularioData copyWith({
    EducacaoData? educacao,
    TrabalhoData? trabalho,
    SaneamentoData? saneamento,
    SaudeData? saude,
    HabitacaoData? habitacao,
    AlimentacaoData? alimentacao,
  }) => FormularioData(
    educacao: educacao ?? this.educacao,
    trabalho: trabalho ?? this.trabalho,
    saneamento: saneamento ?? this.saneamento,
    saude: saude ?? this.saude,
    habitacao: habitacao ?? this.habitacao,
    alimentacao: alimentacao ?? this.alimentacao,
  );

  @override
  String toString() =>
      'FormularioData(educacao: $educacao, trabalho: $trabalho, saneamento: $saneamento, saude: $saude, habitacao: $habitacao, alimentacao: $alimentacao)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormularioData &&
          other.educacao == educacao &&
          other.trabalho == trabalho &&
          other.saneamento == saneamento &&
          other.saude == saude &&
          other.habitacao == habitacao &&
          other.alimentacao == alimentacao;

  @override
  int get hashCode =>
      educacao.hashCode ^
      trabalho.hashCode ^
      saneamento.hashCode ^
      saude.hashCode ^
      habitacao.hashCode ^
      alimentacao.hashCode;
}
