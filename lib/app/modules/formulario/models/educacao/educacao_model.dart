import '../../catalog/dss_schema.dart';

/// Dimensão Educação.
///
/// Campos categóricos e de texto livre são canônicos: armazenam o `code`
/// (snake_case), nunca o rótulo exibido. `null` significa "não respondido".
///
/// Booleanos são `bool?` para distinguir semanticamente três estados:
///   - `true`  = Sim;
///   - `false` = Não;
///   - `null`  = não respondido (nunca confundido com "Não").
class EducacaoModel {
  final bool? estuda;
  final String? escolaridade;
  final String? situacaoEstudosGestacao;
  final List<String> dificuldadesEducacao;
  final bool? entendeOrientacoes;
  final bool? fezCursoQualificacaoProfissional;

  const EducacaoModel({
    this.estuda,
    this.escolaridade,
    this.situacaoEstudosGestacao,
    this.dificuldadesEducacao = const [],
    this.entendeOrientacoes,
    this.fezCursoQualificacaoProfissional,
  });

  factory EducacaoModel.empty() => const EducacaoModel();

  Map<String, dynamic> toMap() => {
    'estuda_atualmente': estuda,
    'escolaridade': escolaridade,
    'situacao_estudos_gestacao': situacaoEstudosGestacao,
    'dificuldades_educacao': dificuldadesEducacao,
    'entende_orientacoes_saude': entendeOrientacoes,
    'fez_curso_qualificacao_profissional': fezCursoQualificacaoProfissional,
  };

  factory EducacaoModel.fromMap(Map<String, dynamic> map) => EducacaoModel(
    estuda: map['estuda_atualmente'] as bool?,
    escolaridade: map['escolaridade'] as String?,
    situacaoEstudosGestacao: map['situacao_estudos_gestacao'] as String?,
    dificuldadesEducacao: List<String>.from((map['dificuldades_educacao'] as List?) ?? const []),
    entendeOrientacoes: map['entende_orientacoes_saude'] as bool?,
    fezCursoQualificacaoProfissional: map['fez_curso_qualificacao_profissional'] as bool?,
  );

  EducacaoModel copyWith({
    bool? estuda,
    String? escolaridade,
    String? situacaoEstudosGestacao,
    List<String>? dificuldadesEducacao,
    bool? entendeOrientacoes,
    bool? fezCursoQualificacaoProfissional,
  }) {
    return EducacaoModel(
      estuda: estuda ?? this.estuda,
      escolaridade: escolaridade ?? this.escolaridade,
      situacaoEstudosGestacao: situacaoEstudosGestacao ?? this.situacaoEstudosGestacao,
      dificuldadesEducacao: dificuldadesEducacao ?? this.dificuldadesEducacao,
      entendeOrientacoes: entendeOrientacoes ?? this.entendeOrientacoes,
      fezCursoQualificacaoProfissional:
          fezCursoQualificacaoProfissional ?? this.fezCursoQualificacaoProfissional,
    );
  }

  @override
  String toString() =>
      'EducacaoModel(escolaridade: $escolaridade, estuda: $estuda, situacaoEstudosGestacao: $situacaoEstudosGestacao, dificuldadesEducacao: $dificuldadesEducacao)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducacaoModel &&
          other.estuda == estuda &&
          other.escolaridade == escolaridade &&
          other.situacaoEstudosGestacao == situacaoEstudosGestacao &&
          DssSchema.listsEqual(other.dificuldadesEducacao, dificuldadesEducacao) &&
          other.entendeOrientacoes == entendeOrientacoes &&
          other.fezCursoQualificacaoProfissional == fezCursoQualificacaoProfissional;

  @override
  int get hashCode => Object.hash(
    estuda,
    escolaridade,
    situacaoEstudosGestacao,
    Object.hashAll(dificuldadesEducacao),
    entendeOrientacoes,
    fezCursoQualificacaoProfissional,
  );
}
