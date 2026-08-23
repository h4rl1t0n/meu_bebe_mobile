import '../../catalog/dss_schema.dart';

/// Dimensão Habitação.
class HabitacaoModel {
  final String? tipoMoradia;
  final String? materialMoradia;
  final int numeroPessoas;
  final int numeroComodos;

  /// Nº de cômodos da residência utilizados para dormir (não necessariamente
  /// quartos arquitetonicamente separados). Sempre `<= numeroComodos`.
  final int numeroDormitorios;
  final List<String> itensResidencia;

  /// Percepção subjetiva da segurança da residência (chave `seguranca_residencia`).
  final String? segurancaResidencia;

  /// Múltipla escolha de melhorias desejadas (códigos canônicos de
  /// `MelhoriaMoradia`). `sem_melhorias` é mutuamente exclusiva.
  final List<String> melhoriasDesejadas;
  final bool? facilAcessoSaude;

  const HabitacaoModel({
    this.tipoMoradia,
    this.materialMoradia,
    required this.numeroPessoas,
    required this.numeroComodos,
    required this.numeroDormitorios,
    this.itensResidencia = const [],
    this.segurancaResidencia,
    this.melhoriasDesejadas = const [],
    this.facilAcessoSaude,
  });

  factory HabitacaoModel.empty() => const HabitacaoModel(
    numeroPessoas: 0,
    numeroComodos: 0,
    numeroDormitorios: 0,
  );

  Map<String, dynamic> toMap() => {
    'tipo_moradia': tipoMoradia,
    'material_moradia': materialMoradia,
    'numero_pessoas': numeroPessoas,
    'numero_comodos': numeroComodos,
    'numero_dormitorios': numeroDormitorios,
    'itens_residencia': itensResidencia,
    'seguranca_residencia': segurancaResidencia,
    'melhorias_desejadas': melhoriasDesejadas,
    'facil_acesso_saude': facilAcessoSaude,
  };

  factory HabitacaoModel.fromMap(Map<String, dynamic> map) => HabitacaoModel(
    tipoMoradia: map['tipo_moradia'] as String?,
    materialMoradia: map['material_moradia'] as String?,
    numeroPessoas: (map['numero_pessoas'] ?? 0) as int,
    numeroComodos: (map['numero_comodos'] ?? 0) as int,
    numeroDormitorios: (map['numero_dormitorios'] ?? 0) as int,
    itensResidencia: List<String>.from((map['itens_residencia'] as List?) ?? const []),
    segurancaResidencia: map['seguranca_residencia'] as String?,
    melhoriasDesejadas: List<String>.from((map['melhorias_desejadas'] as List?) ?? const []),
    facilAcessoSaude: map['facil_acesso_saude'] as bool?,
  );

  HabitacaoModel copyWith({
    String? tipoMoradia,
    String? materialMoradia,
    int? numeroPessoas,
    int? numeroComodos,
    int? numeroDormitorios,
    List<String>? itensResidencia,
    String? segurancaResidencia,
    List<String>? melhoriasDesejadas,
    bool? facilAcessoSaude,
  }) => HabitacaoModel(
    tipoMoradia: tipoMoradia ?? this.tipoMoradia,
    materialMoradia: materialMoradia ?? this.materialMoradia,
    numeroPessoas: numeroPessoas ?? this.numeroPessoas,
    numeroComodos: numeroComodos ?? this.numeroComodos,
    numeroDormitorios: numeroDormitorios ?? this.numeroDormitorios,
    itensResidencia: itensResidencia ?? this.itensResidencia,
    segurancaResidencia: segurancaResidencia ?? this.segurancaResidencia,
    melhoriasDesejadas: melhoriasDesejadas ?? this.melhoriasDesejadas,
    facilAcessoSaude: facilAcessoSaude ?? this.facilAcessoSaude,
  );

  @override
  String toString() =>
      'HabitacaoModel(tipoMoradia: $tipoMoradia, materialMoradia: $materialMoradia, numeroPessoas: $numeroPessoas)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitacaoModel &&
          other.tipoMoradia == tipoMoradia &&
          other.materialMoradia == materialMoradia &&
          other.numeroPessoas == numeroPessoas &&
          other.numeroComodos == numeroComodos &&
          other.numeroDormitorios == numeroDormitorios &&
          DssSchema.listsEqual(other.itensResidencia, itensResidencia) &&
          other.segurancaResidencia == segurancaResidencia &&
          DssSchema.listsEqual(other.melhoriasDesejadas, melhoriasDesejadas) &&
          other.facilAcessoSaude == facilAcessoSaude;

  @override
  int get hashCode => Object.hash(
    tipoMoradia,
    materialMoradia,
    numeroPessoas,
    numeroComodos,
    numeroDormitorios,
    Object.hashAll(itensResidencia),
    segurancaResidencia,
    Object.hashAll(melhoriasDesejadas),
    facilAcessoSaude,
  );
}
