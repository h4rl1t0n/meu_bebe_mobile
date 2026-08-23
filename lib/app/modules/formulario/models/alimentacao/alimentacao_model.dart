import '../../catalog/dss_schema.dart';

/// Dimensão Alimentação.
///
/// `refeicoesPorDia` é uma categoria ordinal canônica (`uma_duas`, `tres`,
/// `quatro_mais`), não um número bruto de refeições.
class AlimentacaoModel {
  final String? refeicoesPorDia;
  final bool insegurancaAlimentar;
  final List<String> alimentosConsumidos;
  final String? fonteAlimentos;
  final bool mudancaAlimentacaoGestacao;
  final bool usaSuplementos;
  final String? avaliacaoAlimentacao;

  const AlimentacaoModel({
    this.refeicoesPorDia,
    required this.insegurancaAlimentar,
    this.alimentosConsumidos = const [],
    this.fonteAlimentos,
    required this.mudancaAlimentacaoGestacao,
    required this.usaSuplementos,
    this.avaliacaoAlimentacao,
  });

  factory AlimentacaoModel.empty() => const AlimentacaoModel(
    insegurancaAlimentar: false,
    mudancaAlimentacaoGestacao: false,
    usaSuplementos: false,
  );

  Map<String, dynamic> toMap() => {
    'refeicoes_por_dia': refeicoesPorDia,
    'inseguranca_alimentar': insegurancaAlimentar,
    'alimentos_consumidos': alimentosConsumidos,
    'fonte_alimentos': fonteAlimentos,
    'mudanca_alimentacao_gestacao': mudancaAlimentacaoGestacao,
    'usa_suplementos': usaSuplementos,
    'avaliacao_alimentacao': avaliacaoAlimentacao,
  };

  factory AlimentacaoModel.fromMap(Map<String, dynamic> map) => AlimentacaoModel(
    refeicoesPorDia: map['refeicoes_por_dia'] as String?,
    insegurancaAlimentar: map['inseguranca_alimentar'] == true,
    alimentosConsumidos: List<String>.from((map['alimentos_consumidos'] as List?) ?? const []),
    fonteAlimentos: map['fonte_alimentos'] as String?,
    mudancaAlimentacaoGestacao: map['mudanca_alimentacao_gestacao'] == true,
    usaSuplementos: map['usa_suplementos'] == true,
    avaliacaoAlimentacao: map['avaliacao_alimentacao'] as String?,
  );

  AlimentacaoModel copyWith({
    String? refeicoesPorDia,
    bool? insegurancaAlimentar,
    List<String>? alimentosConsumidos,
    String? fonteAlimentos,
    bool? mudancaAlimentacaoGestacao,
    bool? usaSuplementos,
    String? avaliacaoAlimentacao,
  }) => AlimentacaoModel(
    refeicoesPorDia: refeicoesPorDia ?? this.refeicoesPorDia,
    insegurancaAlimentar: insegurancaAlimentar ?? this.insegurancaAlimentar,
    alimentosConsumidos: alimentosConsumidos ?? this.alimentosConsumidos,
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
          DssSchema.listsEqual(other.alimentosConsumidos, alimentosConsumidos) &&
          other.fonteAlimentos == fonteAlimentos &&
          other.mudancaAlimentacaoGestacao == mudancaAlimentacaoGestacao &&
          other.usaSuplementos == usaSuplementos &&
          other.avaliacaoAlimentacao == avaliacaoAlimentacao;

  @override
  int get hashCode => Object.hash(
    refeicoesPorDia,
    insegurancaAlimentar,
    Object.hashAll(alimentosConsumidos),
    fonteAlimentos,
    mudancaAlimentacaoGestacao,
    usaSuplementos,
    avaliacaoAlimentacao,
  );
}
