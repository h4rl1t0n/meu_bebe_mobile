import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/alimentacao/alimentacao_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/educacao/educacao_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/formulario_data.dart';
import 'package:meu_bebe/app/modules/formulario/models/habitacao/habitacao_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/saneamento/saneamento_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/saude/saude_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/trabalho/trabalho_model.dart';

FormularioData _sample() => FormularioData(
  educacao: const EducacaoModel(
    estuda: true,
    escolaridade: 'medio_completo',
    situacaoEstudosGestacao: 'nao_interrompeu',
    dificuldadesEducacao: ['falta_dinheiro'],
    entendeOrientacoes: true,
    fezCursoQualificacaoProfissional: false,
  ),
  trabalho: const TrabalhoModel(
    empregado: true,
    tipoEmprego: 'clt',
    faixaRenda: 'ate_1_sm',
    permitePreNatal: true,
    ambienteSeguro: true,
    temPausas: false,
    beneficiosTrabalho: ['vale_transporte'],
  ),
  saneamento: SaneamentoModel.empty(),
  saude: SaudeModel.empty(),
  habitacao: HabitacaoModel.empty(),
  alimentacao: const AlimentacaoModel(
    refeicoesPorDia: 'tres',
    deixouDeComerFaltaDinheiro: false,
    alimentosConsumidos: ['frutas_verduras', 'feijao_leguminosas'],
    fonteAlimentos: ['supermercado_feira', 'horta_propria'],
    mudancaAlimentacaoGestacao: true,
    usaSuplementos: true,
    avaliacaoAlimentacao: 'boa',
  ),
);

void main() {
  group('FormularioData', () {
    test('consolida as 6 dimensões em toMap aninhado e versionado', () {
      final map = _sample().toMap();

      expect(map['schema_version'], '1.13');
      expect(map.containsKey('educacao'), isTrue);
      expect(map.containsKey('trabalho'), isTrue);
      expect(map.containsKey('saneamento'), isTrue);
      expect(map.containsKey('saude'), isTrue);
      expect(map.containsKey('habitacao'), isTrue);
      expect(map.containsKey('alimentacao'), isTrue);

      // Não é flat: chaves de campo não devem aparecer no topo.
      expect(map.containsKey('escolaridade'), isFalse);
      expect(map['educacao'], isA<Map<String, dynamic>>());
    });

    test('toFlatMap produz chaves dimensao.campo sem schema_version', () {
      final flat = _sample().toFlatMap();

      expect(flat['educacao.escolaridade'], 'medio_completo');
      expect(flat['educacao.estuda_atualmente'], isTrue);
      expect(flat['educacao.situacao_estudos_gestacao'], 'nao_interrompeu');
      expect(flat['trabalho.tipo_emprego'], 'clt');
      expect(flat['alimentacao.refeicoes_por_dia'], 'tres');
      expect(flat['alimentacao.fonte_alimentos'], ['supermercado_feira', 'horta_propria']);
      expect(flat.containsKey('schema_version'), isFalse);
    });

    test('fromMap/toMap preserva as 6 dimensões (round-trip)', () {
      final restored = FormularioData.fromMap(_sample().toMap());

      expect(restored, _sample());
    });
  });
}
