import '../../catalog/dss_schema.dart';

/// Dimensão Saúde.
///
/// `cadastradaUBS` é independente de `acessoUBS`: `null` significa apenas
/// "não respondido" (o vínculo com a UBS não depende do meio de transporte).
class SaudeModel {
  final String? distanciaUBS;
  final bool? faltouConsulta;
  final String? acessoUBS;
  final bool? cadastradaUBS;
  final List<String> servicosPreNatal;
  final bool? examesPreNatalCompletos;
  final bool? vacinasEmDia;
  final String? avaliacaoPreNatal;

  /// Dificuldades de acesso/utilização dos serviços de saúde (múltipla
  /// escolha, códigos canônicos de [DificuldadeSaude]).
  final List<String> dificuldadesSaude;

  const SaudeModel({
    this.distanciaUBS,
    this.faltouConsulta,
    this.acessoUBS,
    this.cadastradaUBS,
    this.servicosPreNatal = const [],
    this.examesPreNatalCompletos,
    this.vacinasEmDia,
    this.avaliacaoPreNatal,
    this.dificuldadesSaude = const [],
  });

  factory SaudeModel.empty() => const SaudeModel();

  Map<String, dynamic> toMap() => {
    'distancia_ubs': distanciaUBS,
    'faltou_consulta': faltouConsulta,
    'acesso_ubs': acessoUBS,
    'cadastrada_ubs': cadastradaUBS,
    'servicos_pre_natal': servicosPreNatal,
    'exames_pre_natal_completos': examesPreNatalCompletos,
    'vacinas_em_dia': vacinasEmDia,
    'avaliacao_pre_natal': avaliacaoPreNatal,
    'dificuldades_saude': dificuldadesSaude,
  };

  factory SaudeModel.fromMap(Map<String, dynamic> map) => SaudeModel(
    distanciaUBS: map['distancia_ubs'] as String?,
    faltouConsulta: map['faltou_consulta'] as bool?,
    acessoUBS: map['acesso_ubs'] as String?,
    cadastradaUBS: map['cadastrada_ubs'] as bool?,
    servicosPreNatal: List<String>.from((map['servicos_pre_natal'] as List?) ?? const []),
    examesPreNatalCompletos: map['exames_pre_natal_completos'] as bool?,
    vacinasEmDia: map['vacinas_em_dia'] as bool?,
    avaliacaoPreNatal: map['avaliacao_pre_natal'] as String?,
    dificuldadesSaude: List<String>.from((map['dificuldades_saude'] as List?) ?? const []),
  );

  SaudeModel copyWith({
    String? distanciaUBS,
    bool? faltouConsulta,
    String? acessoUBS,
    bool? cadastradaUBS,
    List<String>? servicosPreNatal,
    bool? examesPreNatalCompletos,
    bool? vacinasEmDia,
    String? avaliacaoPreNatal,
    List<String>? dificuldadesSaude,
  }) => SaudeModel(
    distanciaUBS: distanciaUBS ?? this.distanciaUBS,
    faltouConsulta: faltouConsulta ?? this.faltouConsulta,
    acessoUBS: acessoUBS ?? this.acessoUBS,
    cadastradaUBS: cadastradaUBS ?? this.cadastradaUBS,
    servicosPreNatal: servicosPreNatal ?? this.servicosPreNatal,
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
          other.acessoUBS == acessoUBS &&
          other.cadastradaUBS == cadastradaUBS &&
          DssSchema.listsEqual(other.servicosPreNatal, servicosPreNatal) &&
          other.examesPreNatalCompletos == examesPreNatalCompletos &&
          other.vacinasEmDia == vacinasEmDia &&
          other.avaliacaoPreNatal == avaliacaoPreNatal &&
          DssSchema.listsEqual(other.dificuldadesSaude, dificuldadesSaude);

  @override
  int get hashCode => Object.hash(
    distanciaUBS,
    faltouConsulta,
    acessoUBS,
    cadastradaUBS,
    Object.hashAll(servicosPreNatal),
    examesPreNatalCompletos,
    vacinasEmDia,
    avaliacaoPreNatal,
    Object.hashAll(dificuldadesSaude),
  );
}
