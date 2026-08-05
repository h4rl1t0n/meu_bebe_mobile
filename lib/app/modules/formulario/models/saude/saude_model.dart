class SaudeModel {
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

  const SaudeModel({
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

  factory SaudeModel.empty() => const SaudeModel(
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

  factory SaudeModel.fromMap(Map<String, dynamic> map) => SaudeModel(
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

  SaudeModel copyWith({
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
  }) => SaudeModel(
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
      'SaudeModel(distanciaUBS: $distanciaUBS, cadastradaUBS: $cadastradaUBS, avaliacaoPreNatal: $avaliacaoPreNatal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaudeModel &&
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
