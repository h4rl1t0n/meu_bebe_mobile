import '../../catalog/dss_schema.dart';

/// Dimensão Habitação.
class HabitacaoModel {
  final String? tipoMoradia;
  final int numeroPessoas;
  final int numeroComodos;
  final List<String> itensResidencia;
  final String? segurancaEstrutural;

  /// Texto livre (relato qualitativo). NÃO entra no modelo tabular inicial —
  /// preservado no JSON.
  final String? melhoriasDesejadas;
  final bool facilAcessoSaude;

  const HabitacaoModel({
    this.tipoMoradia,
    required this.numeroPessoas,
    required this.numeroComodos,
    this.itensResidencia = const [],
    this.segurancaEstrutural,
    this.melhoriasDesejadas,
    required this.facilAcessoSaude,
  });

  factory HabitacaoModel.empty() => const HabitacaoModel(
    numeroPessoas: 0,
    numeroComodos: 0,
    facilAcessoSaude: false,
  );

  Map<String, dynamic> toMap() => {
    'tipo_moradia': tipoMoradia,
    'numero_pessoas': numeroPessoas,
    'numero_comodos': numeroComodos,
    'itens_residencia': itensResidencia,
    'seguranca_residencia': segurancaEstrutural,
    'melhorias_desejadas': melhoriasDesejadas,
    'facil_acesso_saude': facilAcessoSaude,
  };

  factory HabitacaoModel.fromMap(Map<String, dynamic> map) => HabitacaoModel(
    tipoMoradia: map['tipo_moradia'] as String?,
    numeroPessoas: (map['numero_pessoas'] ?? 0) as int,
    numeroComodos: (map['numero_comodos'] ?? 0) as int,
    itensResidencia: List<String>.from((map['itens_residencia'] as List?) ?? const []),
    segurancaEstrutural: map['seguranca_residencia'] as String?,
    melhoriasDesejadas: map['melhorias_desejadas'] as String?,
    facilAcessoSaude: map['facil_acesso_saude'] == true,
  );

  HabitacaoModel copyWith({
    String? tipoMoradia,
    int? numeroPessoas,
    int? numeroComodos,
    List<String>? itensResidencia,
    String? segurancaEstrutural,
    String? melhoriasDesejadas,
    bool? facilAcessoSaude,
  }) => HabitacaoModel(
    tipoMoradia: tipoMoradia ?? this.tipoMoradia,
    numeroPessoas: numeroPessoas ?? this.numeroPessoas,
    numeroComodos: numeroComodos ?? this.numeroComodos,
    itensResidencia: itensResidencia ?? this.itensResidencia,
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
          DssSchema.listsEqual(other.itensResidencia, itensResidencia) &&
          other.segurancaEstrutural == segurancaEstrutural &&
          other.melhoriasDesejadas == melhoriasDesejadas &&
          other.facilAcessoSaude == facilAcessoSaude;

  @override
  int get hashCode => Object.hash(
    tipoMoradia,
    numeroPessoas,
    numeroComodos,
    Object.hashAll(itensResidencia),
    segurancaEstrutural,
    melhoriasDesejadas,
    facilAcessoSaude,
  );
}
