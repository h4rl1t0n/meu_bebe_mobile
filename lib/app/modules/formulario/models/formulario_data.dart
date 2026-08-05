import 'alimentacao/alimentacao_model.dart';
import 'educacao/educacao_model.dart';
import 'habitacao/habitacao_model.dart';
import 'saneamento/saneamento_model.dart';
import 'saude/saude_model.dart';
import 'trabalho/trabalho_model.dart';

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
    ...educacao.toMap(),
    ...trabalho.toMap(),
    ...saneamento.toMap(),
    ...saude.toMap(),
    ...habitacao.toMap(),
    ...alimentacao.toMap(),
  };

  factory FormularioData.fromMap(Map<String, dynamic> map) => FormularioData(
    educacao: EducacaoModel.fromMap(map),
    trabalho: TrabalhoModel.fromMap(map),
    saneamento: SaneamentoModel.fromMap(map),
    saude: SaudeModel.fromMap(map),
    habitacao: HabitacaoModel.fromMap(map),
    alimentacao: AlimentacaoModel.fromMap(map),
  );

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
