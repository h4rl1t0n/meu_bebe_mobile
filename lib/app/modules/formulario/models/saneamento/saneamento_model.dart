class SaneamentoModel {
  final String fonteAgua;
  final String interrupcoesAgua;
  final String destinoEsgoto;
  final String coletaLixo;
  final bool preocupacaoAgua;
  final String cuidadosVetores;

  const SaneamentoModel({
    required this.fonteAgua,
    required this.interrupcoesAgua,
    required this.destinoEsgoto,
    required this.coletaLixo,
    required this.preocupacaoAgua,
    required this.cuidadosVetores,
  });

  factory SaneamentoModel.empty() => const SaneamentoModel(
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

  factory SaneamentoModel.fromMap(Map<String, dynamic> map) => SaneamentoModel(
    fonteAgua: map['fonte_agua'] ?? '',
    interrupcoesAgua: map['interrupcoes_agua'] ?? '',
    destinoEsgoto: map['destino_esgoto'] ?? '',
    coletaLixo: map['coleta_lixo'] ?? '',
    preocupacaoAgua: (map['preocupacao_agua'] ?? 0) == 1,
    cuidadosVetores: map['cuidados_vetores'] ?? '',
  );

  SaneamentoModel copyWith({
    String? fonteAgua,
    String? interrupcoesAgua,
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
  String toString() {
    return 'SaneamentoModel(fonteAgua: $fonteAgua, destinoEsgoto: $destinoEsgoto, coletaLixo: $coletaLixo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SaneamentoModel &&
            other.fonteAgua == fonteAgua &&
            other.interrupcoesAgua == interrupcoesAgua &&
            other.destinoEsgoto == destinoEsgoto &&
            other.coletaLixo == coletaLixo &&
            other.preocupacaoAgua == preocupacaoAgua &&
            other.cuidadosVetores == cuidadosVetores;
  }

  @override
  int get hashCode {
    return fonteAgua.hashCode ^
        interrupcoesAgua.hashCode ^
        destinoEsgoto.hashCode ^
        coletaLixo.hashCode ^
        preocupacaoAgua.hashCode ^
        cuidadosVetores.hashCode;
  }
}
