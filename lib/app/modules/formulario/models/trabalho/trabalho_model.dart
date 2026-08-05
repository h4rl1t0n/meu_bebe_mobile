class TrabalhoModel {
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

  const TrabalhoModel({
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

  factory TrabalhoModel.empty() {
    return const TrabalhoModel(
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
  }

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory TrabalhoModel.fromMap(Map<String, dynamic> map) {
    return TrabalhoModel(
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
  }

  TrabalhoModel copyWith({
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
  }) {
    return TrabalhoModel(
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
  }

  @override
  String toString() {
    return 'TrabalhoModel(empregado: $empregado, tipoEmprego: $tipoEmprego, faixaRenda: $faixaRenda)';
  }
}
