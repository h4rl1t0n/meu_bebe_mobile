import '../../catalog/dss_schema.dart';

/// Dimensão Trabalho e Renda.
///
/// Os campos condicionados por `empregado` são anuláveis: `null` significa
/// "não se aplica" (ex.: `tipo_emprego` quando desempregada).
class TrabalhoModel {
  final bool empregado;
  final String? tipoEmprego;

  /// Faixa de renda mensal **familiar** (código canônico de [FaixaRenda]).
  /// Independente de `empregado`: é coletada tanto para empregadas quanto para
  /// desempregadas.
  final String? faixaRenda;
  final bool? permitePreNatal;
  final bool? ambienteSeguro;
  final bool? temPausas;
  final List<String>? beneficiosTrabalho;

  /// Motivo do desemprego (código canônico de [MotivoDesemprego]).
  /// `null` quando não se aplica (empregada).
  final String? motivoDesemprego;

  /// Recebe benefício social (ex.: Auxílio Brasil/Bolsa Família).
  /// Independente de `empregado`: aplica-se tanto a empregadas quanto a
  /// desempregadas; `null` significa apenas "não respondido".
  final bool? recebeBeneficioSocial;

  /// Impacto da gestação na situação de trabalho (código canônico de
  /// [ImpactoGestacaoTrabalho]).
  final String? impactoGestacaoTrabalho;

  const TrabalhoModel({
    required this.empregado,
    this.tipoEmprego,
    this.faixaRenda,
    this.permitePreNatal,
    this.ambienteSeguro,
    this.temPausas,
    this.beneficiosTrabalho,
    this.motivoDesemprego,
    this.recebeBeneficioSocial,
    this.impactoGestacaoTrabalho,
  });

  factory TrabalhoModel.empty() => const TrabalhoModel(empregado: false);

  Map<String, dynamic> toMap() => {
    'empregado': empregado,
    'tipo_emprego': tipoEmprego,
    'faixa_renda': faixaRenda,
    'trabalho_permite_pre_natal': permitePreNatal,
    'ambiente_trabalho_seguro': ambienteSeguro,
    'tem_pausas_descanso': temPausas,
    'beneficios_trabalho': beneficiosTrabalho,
    'motivo_desemprego': motivoDesemprego,
    'recebe_beneficio_social': recebeBeneficioSocial,
    'impacto_gestacao_trabalho': impactoGestacaoTrabalho,
  };

  factory TrabalhoModel.fromMap(Map<String, dynamic> map) => TrabalhoModel(
    empregado: map['empregado'] == true,
    tipoEmprego: map['tipo_emprego'] as String?,
    faixaRenda: map['faixa_renda'] as String?,
    permitePreNatal: map['trabalho_permite_pre_natal'] as bool?,
    ambienteSeguro: map['ambiente_trabalho_seguro'] as bool?,
    temPausas: map['tem_pausas_descanso'] as bool?,
    beneficiosTrabalho: (map['beneficios_trabalho'] as List?)?.cast<String>(),
    motivoDesemprego: map['motivo_desemprego'] as String?,
    recebeBeneficioSocial: map['recebe_beneficio_social'] as bool?,
    impactoGestacaoTrabalho: map['impacto_gestacao_trabalho'] as String?,
  );

  TrabalhoModel copyWith({
    bool? empregado,
    String? tipoEmprego,
    String? faixaRenda,
    bool? permitePreNatal,
    bool? ambienteSeguro,
    bool? temPausas,
    List<String>? beneficiosTrabalho,
    String? motivoDesemprego,
    bool? recebeBeneficioSocial,
    String? impactoGestacaoTrabalho,
  }) {
    return TrabalhoModel(
      empregado: empregado ?? this.empregado,
      tipoEmprego: tipoEmprego ?? this.tipoEmprego,
      faixaRenda: faixaRenda ?? this.faixaRenda,
      permitePreNatal: permitePreNatal ?? this.permitePreNatal,
      ambienteSeguro: ambienteSeguro ?? this.ambienteSeguro,
      temPausas: temPausas ?? this.temPausas,
      beneficiosTrabalho: beneficiosTrabalho ?? this.beneficiosTrabalho,
      motivoDesemprego: motivoDesemprego ?? this.motivoDesemprego,
      recebeBeneficioSocial: recebeBeneficioSocial ?? this.recebeBeneficioSocial,
      impactoGestacaoTrabalho: impactoGestacaoTrabalho ?? this.impactoGestacaoTrabalho,
    );
  }

  @override
  String toString() =>
      'TrabalhoModel(empregado: $empregado, tipoEmprego: $tipoEmprego, faixaRenda: $faixaRenda)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrabalhoModel &&
          other.empregado == empregado &&
          other.tipoEmprego == tipoEmprego &&
          other.faixaRenda == faixaRenda &&
          other.permitePreNatal == permitePreNatal &&
          other.ambienteSeguro == ambienteSeguro &&
          other.temPausas == temPausas &&
          DssSchema.listsEqual(other.beneficiosTrabalho, beneficiosTrabalho) &&
          other.motivoDesemprego == motivoDesemprego &&
          other.recebeBeneficioSocial == recebeBeneficioSocial &&
          other.impactoGestacaoTrabalho == impactoGestacaoTrabalho;

  @override
  int get hashCode => Object.hash(
    empregado,
    tipoEmprego,
    faixaRenda,
    permitePreNatal,
    ambienteSeguro,
    temPausas,
    Object.hashAll(beneficiosTrabalho ?? const []),
    motivoDesemprego,
    recebeBeneficioSocial,
    impactoGestacaoTrabalho,
  );
}
