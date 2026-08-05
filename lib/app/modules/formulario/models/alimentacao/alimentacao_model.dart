class AlimentacaoModel {
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

  const AlimentacaoModel({
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

  factory AlimentacaoModel.empty() => const AlimentacaoModel(
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

  factory AlimentacaoModel.fromMap(Map<String, dynamic> map) => AlimentacaoModel(
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

  AlimentacaoModel copyWith({
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
  }) => AlimentacaoModel(
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
      'AlimentacaoModel(refeicoesPorDia: $refeicoesPorDia, insegurancaAlimentar: $insegurancaAlimentar)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlimentacaoModel &&
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
