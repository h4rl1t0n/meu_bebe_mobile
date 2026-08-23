/// Dimensão Saneamento Básico.
class SaneamentoModel {
  final String? fonteAgua;
  final bool interrupcoesAgua;
  final String? destinoEsgoto;
  final String? coletaLixo;
  final bool preocupacaoAgua;

  /// Texto livre (relato qualitativo). NÃO entra no modelo tabular inicial —
  /// preservado no JSON.
  final String? cuidadosVetores;

  const SaneamentoModel({
    this.fonteAgua,
    required this.interrupcoesAgua,
    this.destinoEsgoto,
    this.coletaLixo,
    required this.preocupacaoAgua,
    this.cuidadosVetores,
  });

  factory SaneamentoModel.empty() =>
      const SaneamentoModel(interrupcoesAgua: false, preocupacaoAgua: false);

  Map<String, dynamic> toMap() => {
    'fonte_agua': fonteAgua,
    'interrupcoes_agua': interrupcoesAgua,
    'esgotamento_sanitario': destinoEsgoto,
    'coleta_lixo': coletaLixo,
    'problema_saude_agua': preocupacaoAgua,
    'cuidados_vetores': cuidadosVetores,
  };

  factory SaneamentoModel.fromMap(Map<String, dynamic> map) => SaneamentoModel(
    fonteAgua: map['fonte_agua'] as String?,
    interrupcoesAgua: map['interrupcoes_agua'] == true,
    destinoEsgoto: map['esgotamento_sanitario'] as String?,
    coletaLixo: map['coleta_lixo'] as String?,
    preocupacaoAgua: map['problema_saude_agua'] == true,
    cuidadosVetores: map['cuidados_vetores'] as String?,
  );

  SaneamentoModel copyWith({
    String? fonteAgua,
    bool? interrupcoesAgua,
    String? destinoEsgoto,
    String? coletaLixo,
    bool? preocupacaoAgua,
    String? cuidadosVetores,
  }) {
    return SaneamentoModel(
      fonteAgua: fonteAgua ?? this.fonteAgua,
      interrupcoesAgua: interrupcoesAgua ?? this.interrupcoesAgua,
      destinoEsgoto: destinoEsgoto ?? this.destinoEsgoto,
      coletaLixo: coletaLixo ?? this.coletaLixo,
      preocupacaoAgua: preocupacaoAgua ?? this.preocupacaoAgua,
      cuidadosVetores: cuidadosVetores ?? this.cuidadosVetores,
    );
  }

  @override
  String toString() =>
      'SaneamentoModel(fonteAgua: $fonteAgua, destinoEsgoto: $destinoEsgoto, coletaLixo: $coletaLixo)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaneamentoModel &&
          other.fonteAgua == fonteAgua &&
          other.interrupcoesAgua == interrupcoesAgua &&
          other.destinoEsgoto == destinoEsgoto &&
          other.coletaLixo == coletaLixo &&
          other.preocupacaoAgua == preocupacaoAgua &&
          other.cuidadosVetores == cuidadosVetores;

  @override
  int get hashCode => Object.hash(
    fonteAgua,
    interrupcoesAgua,
    destinoEsgoto,
    coletaLixo,
    preocupacaoAgua,
    cuidadosVetores,
  );
}
