class EducacaoModel {
  final String escolaridade;
  final bool estuda;
  final bool interrompeuEstudos;
  final String dificuldadesEscolares;
  final bool entendeOrientacoes;
  final String cursosExtracurriculares;
  final String expectativasEducacionais;

  const EducacaoModel({
    required this.escolaridade,
    required this.estuda,
    required this.interrompeuEstudos,
    required this.dificuldadesEscolares,
    required this.entendeOrientacoes,
    required this.cursosExtracurriculares,
    required this.expectativasEducacionais,
  });

  factory EducacaoModel.empty() {
    return const EducacaoModel(
      escolaridade: '',
      estuda: false,
      interrompeuEstudos: false,
      dificuldadesEscolares: '',
      entendeOrientacoes: false,
      cursosExtracurriculares: '',
      expectativasEducacionais: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'escolaridade': escolaridade,
      'estuda': estuda ? 1 : 0,
      'interrompeu_estudos': interrompeuEstudos ? 1 : 0,
      'dificuldades_escolares': dificuldadesEscolares,
      'entende_orientacoes': entendeOrientacoes ? 1 : 0,
      'cursos_extracurriculares': cursosExtracurriculares,
      'expectativas_educacionais': expectativasEducacionais,
    };
  }

  factory EducacaoModel.fromMap(Map<String, dynamic> map) {
    return EducacaoModel(
      escolaridade: map['escolaridade'] ?? '',
      estuda: (map['estuda'] ?? 0) == 1,
      interrompeuEstudos: (map['interrompeu_estudos'] ?? 0) == 1,
      dificuldadesEscolares: map['dificuldades_escolares'] ?? '',
      entendeOrientacoes: (map['entende_orientacoes'] ?? 0) == 1,
      cursosExtracurriculares: map['cursos_extracurriculares'] ?? '',
      expectativasEducacionais: map['expectativas_educacionais'] ?? '',
    );
  }

  EducacaoModel copyWith({
    String? escolaridade,
    bool? estuda,
    bool? interrompeuEstudos,
    String? dificuldadesEscolares,
    bool? entendeOrientacoes,
    String? cursosExtracurriculares,
    String? expectativasEducacionais,
  }) {
    return EducacaoModel(
      escolaridade: escolaridade ?? this.escolaridade,
      estuda: estuda ?? this.estuda,
      interrompeuEstudos: interrompeuEstudos ?? this.interrompeuEstudos,
      dificuldadesEscolares: dificuldadesEscolares ?? this.dificuldadesEscolares,
      entendeOrientacoes: entendeOrientacoes ?? this.entendeOrientacoes,
      cursosExtracurriculares: cursosExtracurriculares ?? this.cursosExtracurriculares,
      expectativasEducacionais: expectativasEducacionais ?? this.expectativasEducacionais,
    );
  }

  @override
  String toString() {
    return 'EducacaoModel(escolaridade: $escolaridade, estuda: $estuda, interrompeuEstudos: $interrompeuEstudos)';
  }
}
