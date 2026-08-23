import '../../catalog/dss_schema.dart';

/// Dimensão Alimentação.
///
/// `refeicoesPorDia` é uma categoria ordinal canônica (`uma_duas`, `tres`,
/// `quatro_mais`), não um número bruto de refeições. Campos categóricos e de
/// múltipla escolha armazenam o `code` (snake_case), nunca o rótulo exibido.
///
/// Booleanos são `bool?`: `true` = Sim, `false` = Não, `null` = não respondido
/// (nunca confundido com "Não").
class AlimentacaoModel {
  final String? refeicoesPorDia;
  final bool? deixouDeComerFaltaDinheiro;
  final List<String> alimentosConsumidos;
  final List<String> fonteAlimentos;
  final bool? mudancaAlimentacaoGestacao;
  final bool? usaSuplementos;
  final String? avaliacaoAlimentacao;

  const AlimentacaoModel({
    this.refeicoesPorDia,
    this.deixouDeComerFaltaDinheiro,
    this.alimentosConsumidos = const [],
    this.fonteAlimentos = const [],
    this.mudancaAlimentacaoGestacao,
    this.usaSuplementos,
    this.avaliacaoAlimentacao,
  });

  factory AlimentacaoModel.empty() => const AlimentacaoModel();

  Map<String, dynamic> toMap() => {
    'refeicoes_por_dia': refeicoesPorDia,
    'deixou_de_comer_falta_dinheiro': deixouDeComerFaltaDinheiro,
    'alimentos_consumidos': alimentosConsumidos,
    'fonte_alimentos': fonteAlimentos,
    'mudanca_alimentacao_gestacao': mudancaAlimentacaoGestacao,
    'usa_suplementos': usaSuplementos,
    'avaliacao_alimentacao': avaliacaoAlimentacao,
  };

  factory AlimentacaoModel.fromMap(Map<String, dynamic> map) => AlimentacaoModel(
    refeicoesPorDia: map['refeicoes_por_dia'] as String?,
    deixouDeComerFaltaDinheiro: map['deixou_de_comer_falta_dinheiro'] as bool?,
    alimentosConsumidos: List<String>.from((map['alimentos_consumidos'] as List?) ?? const []),
    fonteAlimentos: List<String>.from((map['fonte_alimentos'] as List?) ?? const []),
    mudancaAlimentacaoGestacao: map['mudanca_alimentacao_gestacao'] as bool?,
    usaSuplementos: map['usa_suplementos'] as bool?,
    avaliacaoAlimentacao: map['avaliacao_alimentacao'] as String?,
  );

  AlimentacaoModel copyWith({
    String? refeicoesPorDia,
    bool? deixouDeComerFaltaDinheiro,
    List<String>? alimentosConsumidos,
    List<String>? fonteAlimentos,
    bool? mudancaAlimentacaoGestacao,
    bool? usaSuplementos,
    String? avaliacaoAlimentacao,
  }) => AlimentacaoModel(
    refeicoesPorDia: refeicoesPorDia ?? this.refeicoesPorDia,
    deixouDeComerFaltaDinheiro: deixouDeComerFaltaDinheiro ?? this.deixouDeComerFaltaDinheiro,
    alimentosConsumidos: alimentosConsumidos ?? this.alimentosConsumidos,
    fonteAlimentos: fonteAlimentos ?? this.fonteAlimentos,
    mudancaAlimentacaoGestacao: mudancaAlimentacaoGestacao ?? this.mudancaAlimentacaoGestacao,
    usaSuplementos: usaSuplementos ?? this.usaSuplementos,
    avaliacaoAlimentacao: avaliacaoAlimentacao ?? this.avaliacaoAlimentacao,
  );

  @override
  String toString() =>
      'AlimentacaoModel(refeicoesPorDia: $refeicoesPorDia, deixouDeComerFaltaDinheiro: $deixouDeComerFaltaDinheiro)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlimentacaoModel &&
          other.refeicoesPorDia == refeicoesPorDia &&
          other.deixouDeComerFaltaDinheiro == deixouDeComerFaltaDinheiro &&
          DssSchema.listsEqual(other.alimentosConsumidos, alimentosConsumidos) &&
          DssSchema.listsEqual(other.fonteAlimentos, fonteAlimentos) &&
          other.mudancaAlimentacaoGestacao == mudancaAlimentacaoGestacao &&
          other.usaSuplementos == usaSuplementos &&
          other.avaliacaoAlimentacao == avaliacaoAlimentacao;

  @override
  int get hashCode => Object.hash(
    refeicoesPorDia,
    deixouDeComerFaltaDinheiro,
    Object.hashAll(alimentosConsumidos),
    Object.hashAll(fonteAlimentos),
    mudancaAlimentacaoGestacao,
    usaSuplementos,
    avaliacaoAlimentacao,
  );
}
