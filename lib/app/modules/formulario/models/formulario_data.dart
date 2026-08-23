import '../catalog/dss_schema.dart';
import 'alimentacao/alimentacao_model.dart';
import 'educacao/educacao_model.dart';
import 'habitacao/habitacao_model.dart';
import 'saneamento/saneamento_model.dart';
import 'saude/saude_model.dart';
import 'trabalho/trabalho_model.dart';

/// Consolida as seis dimensões do formulário DSS.
///
/// `toMap()` produz a representação canônica ANINHADA e versionada (a
/// referência estável do contrato de dados); `toFlatMap()` produz a visão
/// "flat" (`dimensao.campo`) para consumo direto por pipeline de ML/API.
class FormularioData {
  final EducacaoModel educacao;
  final TrabalhoModel trabalho;
  final SaneamentoModel saneamento;
  final SaudeModel saude;
  final HabitacaoModel habitacao;
  final AlimentacaoModel alimentacao;

  const FormularioData({
    required this.educacao,
    required this.trabalho,
    required this.saneamento,
    required this.saude,
    required this.habitacao,
    required this.alimentacao,
  });

  factory FormularioData.empty() => FormularioData(
    educacao: EducacaoModel.empty(),
    trabalho: TrabalhoModel.empty(),
    saneamento: SaneamentoModel.empty(),
    saude: SaudeModel.empty(),
    habitacao: HabitacaoModel.empty(),
    alimentacao: AlimentacaoModel.empty(),
  );

  Map<String, dynamic> toMap() => {
    'schema_version': DssSchema.schemaVersion,
    'educacao': educacao.toMap(),
    'trabalho': trabalho.toMap(),
    'saneamento': saneamento.toMap(),
    'saude': saude.toMap(),
    'habitacao': habitacao.toMap(),
    'alimentacao': alimentacao.toMap(),
  };

  /// Visão plana (`dimensao.campo`) sem `schema_version` — útil para montar
  /// uma linha de dataset. Os campos de múltipla escolha permanecem como
  /// lista de códigos; a expansão one-hot é feita no pipeline, não aqui.
  Map<String, dynamic> toFlatMap() {
    final flat = <String, dynamic>{};
    educacao.toMap().forEach((k, v) => flat['educacao.$k'] = v);
    trabalho.toMap().forEach((k, v) => flat['trabalho.$k'] = v);
    saneamento.toMap().forEach((k, v) => flat['saneamento.$k'] = v);
    saude.toMap().forEach((k, v) => flat['saude.$k'] = v);
    habitacao.toMap().forEach((k, v) => flat['habitacao.$k'] = v);
    alimentacao.toMap().forEach((k, v) => flat['alimentacao.$k'] = v);
    return flat;
  }

  factory FormularioData.fromMap(Map<String, dynamic> map) => FormularioData(
    educacao: EducacaoModel.fromMap(_sub(map, 'educacao')),
    trabalho: TrabalhoModel.fromMap(_sub(map, 'trabalho')),
    saneamento: SaneamentoModel.fromMap(_sub(map, 'saneamento')),
    saude: SaudeModel.fromMap(_sub(map, 'saude')),
    habitacao: HabitacaoModel.fromMap(_sub(map, 'habitacao')),
    alimentacao: AlimentacaoModel.fromMap(_sub(map, 'alimentacao')),
  );

  static Map<String, dynamic> _sub(Map<String, dynamic> map, String key) =>
      Map<String, dynamic>.from((map[key] as Map?) ?? const {});

  FormularioData copyWith({
    EducacaoModel? educacao,
    TrabalhoModel? trabalho,
    SaneamentoModel? saneamento,
    SaudeModel? saude,
    HabitacaoModel? habitacao,
    AlimentacaoModel? alimentacao,
  }) => FormularioData(
    educacao: educacao ?? this.educacao,
    trabalho: trabalho ?? this.trabalho,
    saneamento: saneamento ?? this.saneamento,
    saude: saude ?? this.saude,
    habitacao: habitacao ?? this.habitacao,
    alimentacao: alimentacao ?? this.alimentacao,
  );

  @override
  String toString() =>
      'FormularioData(educacao: $educacao, trabalho: $trabalho, saneamento: $saneamento, saude: $saude, habitacao: $habitacao, alimentacao: $alimentacao)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormularioData &&
          other.educacao == educacao &&
          other.trabalho == trabalho &&
          other.saneamento == saneamento &&
          other.saude == saude &&
          other.habitacao == habitacao &&
          other.alimentacao == alimentacao;

  @override
  int get hashCode =>
      educacao.hashCode ^
      trabalho.hashCode ^
      saneamento.hashCode ^
      saude.hashCode ^
      habitacao.hashCode ^
      alimentacao.hashCode;
}
