import '../../catalog/dss_schema.dart';

/// Dimensão Saneamento Básico.
class SaneamentoModel {
  final String? fonteAgua;
  final bool interrupcoesAgua;
  final String? esgotamentoSanitario;

  /// Regularidade da coleta de lixo (`FrequenciaColetaLixo`).
  final String? frequenciaColetaLixo;

  /// Destinação do lixo quando não há coleta adequada. Aplicável quando
  /// `frequenciaColetaLixo` é `irregular`/`nao_possui`; para `regular`, `null`
  /// significa "não aplicável".
  final String? destinoLixoSemColeta;

  final bool preocupacaoAgua;

  /// Cuidados adotados contra mosquitos e outros vetores (múltipla escolha,
  /// códigos canônicos de [CuidadoVetor]).
  final List<String> cuidadosVetores;

  const SaneamentoModel({
    this.fonteAgua,
    required this.interrupcoesAgua,
    this.esgotamentoSanitario,
    this.frequenciaColetaLixo,
    this.destinoLixoSemColeta,
    required this.preocupacaoAgua,
    this.cuidadosVetores = const [],
  });

  factory SaneamentoModel.empty() =>
      const SaneamentoModel(interrupcoesAgua: false, preocupacaoAgua: false);

  Map<String, dynamic> toMap() => {
    'fonte_agua': fonteAgua,
    'interrupcoes_agua': interrupcoesAgua,
    'esgotamento_sanitario': esgotamentoSanitario,
    'frequencia_coleta_lixo': frequenciaColetaLixo,
    'destino_lixo_sem_coleta': destinoLixoSemColeta,
    'problema_saude_agua': preocupacaoAgua,
    'cuidados_vetores': cuidadosVetores,
  };

  factory SaneamentoModel.fromMap(Map<String, dynamic> map) => SaneamentoModel(
    fonteAgua: map['fonte_agua'] as String?,
    interrupcoesAgua: map['interrupcoes_agua'] == true,
    esgotamentoSanitario: map['esgotamento_sanitario'] as String?,
    frequenciaColetaLixo: map['frequencia_coleta_lixo'] as String?,
    destinoLixoSemColeta: map['destino_lixo_sem_coleta'] as String?,
    preocupacaoAgua: map['problema_saude_agua'] == true,
    cuidadosVetores: List<String>.from((map['cuidados_vetores'] as List?) ?? const []),
  );

  SaneamentoModel copyWith({
    String? fonteAgua,
    bool? interrupcoesAgua,
    String? esgotamentoSanitario,
    String? frequenciaColetaLixo,
    String? destinoLixoSemColeta,
    bool? preocupacaoAgua,
    List<String>? cuidadosVetores,
  }) {
    return SaneamentoModel(
      fonteAgua: fonteAgua ?? this.fonteAgua,
      interrupcoesAgua: interrupcoesAgua ?? this.interrupcoesAgua,
      esgotamentoSanitario: esgotamentoSanitario ?? this.esgotamentoSanitario,
      frequenciaColetaLixo: frequenciaColetaLixo ?? this.frequenciaColetaLixo,
      destinoLixoSemColeta: destinoLixoSemColeta ?? this.destinoLixoSemColeta,
      preocupacaoAgua: preocupacaoAgua ?? this.preocupacaoAgua,
      cuidadosVetores: cuidadosVetores ?? this.cuidadosVetores,
    );
  }

  @override
  String toString() =>
      'SaneamentoModel(fonteAgua: $fonteAgua, esgotamentoSanitario: $esgotamentoSanitario, frequenciaColetaLixo: $frequenciaColetaLixo)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaneamentoModel &&
          other.fonteAgua == fonteAgua &&
          other.interrupcoesAgua == interrupcoesAgua &&
          other.esgotamentoSanitario == esgotamentoSanitario &&
          other.frequenciaColetaLixo == frequenciaColetaLixo &&
          other.destinoLixoSemColeta == destinoLixoSemColeta &&
          other.preocupacaoAgua == preocupacaoAgua &&
          DssSchema.listsEqual(other.cuidadosVetores, cuidadosVetores);

  @override
  int get hashCode => Object.hash(
    fonteAgua,
    interrupcoesAgua,
    esgotamentoSanitario,
    frequenciaColetaLixo,
    destinoLixoSemColeta,
    preocupacaoAgua,
    Object.hashAll(cuidadosVetores),
  );
}
