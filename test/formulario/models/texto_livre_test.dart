import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/alimentacao/alimentacao_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/educacao/educacao_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/formulario_data.dart';
import 'package:meu_bebe/app/modules/formulario/models/habitacao/habitacao_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/saneamento/saneamento_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/saude/saude_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/trabalho/trabalho_model.dart';

/// Garante que os 2 campos de texto livre (qualitativos) remanescentes são
/// preservados como `String?` crua por todo o caminho UI → Controller → Model →
/// FormularioData → toMap → fromMap, sem conversão automática em categoria.
///
/// Deixaram de ser texto livre (viraram categorias canônicas):
///   - `trabalho.motivo_desemprego` e `trabalho.impacto_gestacao_trabalho`
///     (ver `trabalho_options.dart`);
///   - `saude.dificuldades_saude` (ver `DificuldadeSaude`).
FormularioData _data() => FormularioData(
  educacao: EducacaoModel.empty(),
  trabalho: TrabalhoModel.empty(),
  saneamento: const SaneamentoModel(
    interrupcoesAgua: false,
    preocupacaoAgua: false,
    cuidadosVetores: 'Uso repelente e telas nas janelas',
  ),
  saude: const SaudeModel(
    faltouConsulta: false,
    examesPreNatalCompletos: false,
    vacinasEmDia: false,
  ),
  habitacao: const HabitacaoModel(
    numeroPessoas: 0,
    numeroComodos: 0,
    facilAcessoSaude: false,
    melhoriasDesejadas: 'Reformar o banheiro e melhorar a ventilação',
  ),
  alimentacao: AlimentacaoModel.empty(),
);

void main() {
  group('Campos de texto livre (qualitativos)', () {
    test('são preservados no JSON canônico (toMap → fromMap round-trip)', () {
      final data = _data();
      final map = data.toMap();

      expect(map['saneamento'], containsPair('cuidados_vetores', 'Uso repelente e telas nas janelas'));
      expect(map['habitacao'], containsPair('melhorias_desejadas', 'Reformar o banheiro e melhorar a ventilação'));

      final restored = FormularioData.fromMap(map);

      expect(restored.saneamento.cuidadosVetores, 'Uso repelente e telas nas janelas');
      expect(restored.habitacao.melhoriasDesejadas, 'Reformar o banheiro e melhorar a ventilação');
    });

    test('permanecem texto cru no toFlatMap (não viram categoria)', () {
      final flat = _data().toFlatMap();

      expect(flat['saneamento.cuidados_vetores'], 'Uso repelente e telas nas janelas');
      expect(flat['habitacao.melhorias_desejadas'], 'Reformar o banheiro e melhorar a ventilação');
    });

    test('quando vazios, serializam como null (sem perda de simetria)', () {
      final map = FormularioData.empty().toMap();

      expect(map['saneamento']['cuidados_vetores'], isNull);
      expect(map['habitacao']['melhorias_desejadas'], isNull);

      final restored = FormularioData.fromMap(map);
      expect(restored.saneamento.cuidadosVetores, isNull);
      expect(restored.habitacao.melhoriasDesejadas, isNull);
    });
  });
}
