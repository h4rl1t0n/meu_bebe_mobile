class HabitacaoModel {
  final String tipoMoradia;
  final int numeroPessoas;
  final int numeroComodos;
  final bool temAguaEncanada;
  final bool temBanheiro;
  final bool temCozinhaSeparada;
  final String segurancaEstrutural;
  final String melhoriasDesejadas;
  final bool facilAcessoSaude;

  const HabitacaoModel({
    required this.tipoMoradia,
    required this.numeroPessoas,
    required this.numeroComodos,
    required this.temAguaEncanada,
    required this.temBanheiro,
    required this.temCozinhaSeparada,
    required this.segurancaEstrutural,
    required this.melhoriasDesejadas,
    required this.facilAcessoSaude,
  });

  factory HabitacaoModel.empty() => const HabitacaoModel(
    tipoMoradia: '',
    numeroPessoas: 0,
    numeroComodos: 0,
    temAguaEncanada: false,
    temBanheiro: false,
    temCozinhaSeparada: false,
    segurancaEstrutural: '',
    melhoriasDesejadas: '',
    facilAcessoSaude: false,
  );

  Map<String, dynamic> toMap() => {
    'tipo_moradia': tipoMoradia,
    'numero_pessoas': numeroPessoas,
    'numero_comodos': numeroComodos,
    'tem_agua_encanada': temAguaEncanada ? 1 : 0,
    'tem_banheiro': temBanheiro ? 1 : 0,
    'tem_cozinha_separada': temCozinhaSeparada ? 1 : 0,
    'seguranca_estrutural': segurancaEstrutural,
    'melhorias_desejadas': melhoriasDesejadas,
    'facil_acesso_saude': facilAcessoSaude ? 1 : 0,
  };

  factory HabitacaoModel.fromMap(Map<String, dynamic> map) => HabitacaoModel(
    tipoMoradia: map['tipo_moradia'] ?? '',
    numeroPessoas: map['numero_pessoas'] ?? 0,
    numeroComodos: map['numero_comodos'] ?? 0,
    temAguaEncanada: (map['tem_agua_encanada'] ?? 0) == 1,
    temBanheiro: (map['tem_banheiro'] ?? 0) == 1,
    temCozinhaSeparada: (map['tem_cozinha_separada'] ?? 0) == 1,
    segurancaEstrutural: map['seguranca_estrutural'] ?? '',
    melhoriasDesejadas: map['melhorias_desejadas'] ?? '',
    facilAcessoSaude: (map['facil_acesso_saude'] ?? 0) == 1,
  );

  HabitacaoModel copyWith({
    String? tipoMoradia,
    int? numeroPessoas,
    int? numeroComodos,
    bool? temAguaEncanada,
    bool? temBanheiro,
    bool? temCozinhaSeparada,
    String? segurancaEstrutural,
    String? melhoriasDesejadas,
    bool? facilAcessoSaude,
  }) => HabitacaoModel(
    tipoMoradia: tipoMoradia ?? this.tipoMoradia,
    numeroPessoas: numeroPessoas ?? this.numeroPessoas,
    numeroComodos: numeroComodos ?? this.numeroComodos,
    temAguaEncanada: temAguaEncanada ?? this.temAguaEncanada,
    temBanheiro: temBanheiro ?? this.temBanheiro,
    temCozinhaSeparada: temCozinhaSeparada ?? this.temCozinhaSeparada,
    segurancaEstrutural: segurancaEstrutural ?? this.segurancaEstrutural,
    melhoriasDesejadas: melhoriasDesejadas ?? this.melhoriasDesejadas,
    facilAcessoSaude: facilAcessoSaude ?? this.facilAcessoSaude,
  );

  @override
  String toString() =>
      'HabitacaoModel(tipoMoradia: $tipoMoradia, numeroPessoas: $numeroPessoas, numeroComodos: $numeroComodos)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitacaoModel &&
          other.tipoMoradia == tipoMoradia &&
          other.numeroPessoas == numeroPessoas &&
          other.numeroComodos == numeroComodos &&
          other.temAguaEncanada == temAguaEncanada &&
          other.temBanheiro == temBanheiro &&
          other.temCozinhaSeparada == temCozinhaSeparada &&
          other.segurancaEstrutural == segurancaEstrutural &&
          other.melhoriasDesejadas == melhoriasDesejadas &&
          other.facilAcessoSaude == facilAcessoSaude;

  @override
  int get hashCode =>
      tipoMoradia.hashCode ^
      numeroPessoas.hashCode ^
      numeroComodos.hashCode ^
      temAguaEncanada.hashCode ^
      temBanheiro.hashCode ^
      temCozinhaSeparada.hashCode ^
      segurancaEstrutural.hashCode ^
      melhoriasDesejadas.hashCode ^
      facilAcessoSaude.hashCode;
}
