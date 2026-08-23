import '../../catalog/dss_schema.dart';

/// Dimensão Educação.
///
/// Campos categóricos e de texto livre são canônicos: armazenam o `code`
/// (snake_case), nunca o rótulo exibido. `null` significa "não respondido".
class EducacaoModel {
  final bool estuda;
  final String? escolaridade;
  final bool interrompeuEstudos;
  final List<String> dificuldadesEducacao;
  final bool entendeOrientacoes;
  final bool fezCursoExtracurricular;

  const EducacaoModel({
    required this.estuda,
    this.escolaridade,
    required this.interrompeuEstudos,
    this.dificuldadesEducacao = const [],
    required this.entendeOrientacoes,
    required this.fezCursoExtracurricular,
  });

  factory EducacaoModel.empty() => const EducacaoModel(
    estuda: false,
    interrompeuEstudos: false,
    entendeOrientacoes: false,
    fezCursoExtracurricular: false,
  );

  Map<String, dynamic> toMap() => {
    'estuda_atualmente': estuda,
    'escolaridade': escolaridade,
    'interrompeu_estudos_gestacao': interrompeuEstudos,
    'dificuldades_educacao': dificuldadesEducacao,
    'entende_orientacoes_saude': entendeOrientacoes,
    'fez_curso_extracurricular': fezCursoExtracurricular,
  };

  factory EducacaoModel.fromMap(Map<String, dynamic> map) => EducacaoModel(
    estuda: map['estuda_atualmente'] == true,
    escolaridade: map['escolaridade'] as String?,
    interrompeuEstudos: map['interrompeu_estudos_gestacao'] == true,
    dificuldadesEducacao: List<String>.from((map['dificuldades_educacao'] as List?) ?? const []),
    entendeOrientacoes: map['entende_orientacoes_saude'] == true,
    fezCursoExtracurricular: map['fez_curso_extracurricular'] == true,
  );

  EducacaoModel copyWith({
    bool? estuda,
    String? escolaridade,
    bool? interrompeuEstudos,
    List<String>? dificuldadesEducacao,
    bool? entendeOrientacoes,
    bool? fezCursoExtracurricular,
  }) {
    return EducacaoModel(
      estuda: estuda ?? this.estuda,
      escolaridade: escolaridade ?? this.escolaridade,
      interrompeuEstudos: interrompeuEstudos ?? this.interrompeuEstudos,
      dificuldadesEducacao: dificuldadesEducacao ?? this.dificuldadesEducacao,
      entendeOrientacoes: entendeOrientacoes ?? this.entendeOrientacoes,
      fezCursoExtracurricular: fezCursoExtracurricular ?? this.fezCursoExtracurricular,
    );
  }

  @override
  String toString() =>
      'EducacaoModel(escolaridade: $escolaridade, estuda: $estuda, dificuldadesEducacao: $dificuldadesEducacao)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducacaoModel &&
          other.estuda == estuda &&
          other.escolaridade == escolaridade &&
          other.interrompeuEstudos == interrompeuEstudos &&
          DssSchema.listsEqual(other.dificuldadesEducacao, dificuldadesEducacao) &&
          other.entendeOrientacoes == entendeOrientacoes &&
          other.fezCursoExtracurricular == fezCursoExtracurricular;

  @override
  int get hashCode => Object.hash(
    estuda,
    escolaridade,
    interrompeuEstudos,
    Object.hashAll(dificuldadesEducacao),
    entendeOrientacoes,
    fezCursoExtracurricular,
  );
}
