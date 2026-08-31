import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:meu_bebe/app/core/ui/theme/app_theme.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/alimentacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/habitacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/saude_options.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/alimentacao/alimentacao_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/saude/saude_controller.dart';
import 'package:meu_bebe/app/modules/formulario/widgets/dss_question.dart';

/// Testes de COMPONENTE dos widgets reutilizáveis do DSS (FASE 9J-PRE-FIX1).
///
/// Cobrem os itens de aceitação do BLOCO A que não dependem da página completa:
/// pergunta longa integral, alternativa longa integral, pergunta binária,
/// dropdown, escolha única, múltipla escolha, opção exclusiva e "Outro" como
/// opção normal (sem campo de texto livre).

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

/// Localiza o [Text] que renderiza [fullText] (seja via `data` ou via o
/// `textSpan` de um `Text.rich`), exigindo que apareça exatamente uma vez.
Text _findText(WidgetTester tester, String fullText) {
  final finder = find.byWidgetPredicate((w) {
    if (w is! Text) return false;
    if (w.data == fullText) return true;
    return w.textSpan?.toPlainText() == fullText;
  });
  expect(
    finder,
    findsOneWidget,
    reason: 'texto "$fullText" deveria aparecer exatamente uma vez',
  );
  return tester.widget<Text>(finder);
}

DssMultiOption _optionOf(WidgetTester tester, String label) {
  return tester.widget<DssMultiOption>(
    find.byWidgetPredicate((w) => w is DssMultiOption && w.label == label),
  );
}

/// Garante que um texto longo não é truncado: sem `overflow: ellipsis` e sem
/// `maxLines` limitado (o padrão dos componentes é altura dinâmica).
void _expectIntegral(Text text) {
  expect(text.overflow, isNot(TextOverflow.ellipsis));
  expect(text.maxLines, isNull);
}

void main() {
  group('Sem truncamento (itens de aceitação visuais)', () {
    testWidgets('pergunta longa aparece integralmente (sem ellipsis/maxLines)',
        (tester) async {
      const longTitle =
          'Esta é uma pergunta propositalmente longa para assegurar que o '
          'título do formulário DSS nunca é cortado nem exibe reticências, '
          'preservando integralmente o enunciado exibido à gestante em '
          'qualquer largura de tela, independentemente do dispositivo.';

      await tester.pumpWidget(
        _wrap(
          DssQuestionCard(
            child: DssBinaryQuestion(
              title: longTitle,
              value: null,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      _expectIntegral(_findText(tester, longTitle));
    });

    testWidgets('alternativa longa aparece integralmente (sem ellipsis/maxLines)',
        (tester) async {
      const longOption =
          'Alternativa de escolha única com descrição deliberadamente longa '
          'e detalhada, que deve ser exibida por completo, sem cortes, '
          'reticências ou limitação de linhas em qualquer resolução de tela.';

      await tester.pumpWidget(
        _wrap(
          DssSingleChoiceQuestion<String>(
            title: 'Escolha uma alternativa',
            value: null,
            options: const [longOption, 'Outra opção curta'],
            labelOf: (s) => s,
            onChanged: (_) {},
          ),
        ),
      );

      _expectIntegral(_findText(tester, longOption));
    });
  });

  group('DssBinaryQuestion — Sim/Não lado a lado', () {
    testWidgets('três estados null/false/true, opções lado a lado, erro inline',
        (tester) async {
      final controller = SaudeController();
      controller.setShowErrors(true);

      await tester.pumpWidget(
        _wrap(
          Observer(
            builder: (_) => DssBinaryQuestion(
              title: 'Você possui cadastro em uma Unidade Básica de Saúde (UBS)?',
              value: controller.cadastradaUBS,
              onChanged: controller.setCadastradaUBS,
              required: true,
              showError: controller.showErrors,
            ),
          ),
        ),
      );

      // null: erro obrigatório visível, nenhuma opção marcada.
      expect(controller.cadastradaUBS, isNull);
      expect(find.text('Campo obrigatório'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      expect(find.text('Sim'), findsOneWidget);
      expect(find.text('Não'), findsOneWidget);

      // Sim -> true (erro some).
      await tester.tap(find.text('Sim'));
      await tester.pump();
      expect(controller.cadastradaUBS, isTrue);
      expect(find.text('Campo obrigatório'), findsNothing);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

      // Não -> false (distinto de null: segue resposta válida).
      await tester.tap(find.text('Não'));
      await tester.pump();
      expect(controller.cadastradaUBS, isFalse);
      expect(find.text('Campo obrigatório'), findsNothing);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });
  });

  group('DssDropdownQuestion — opções e seleção', () {
    testWidgets('exibe hint, abre todas as opções e seleciona', (tester) async {
      TipoMoradia? selected;

      await tester.pumpWidget(
        _wrap(
          DssDropdownQuestion<TipoMoradia>(
            title: 'Tipo de moradia',
            value: null,
            options: TipoMoradia.values,
            labelOf: (e) => e.label,
            onChanged: (v) => selected = v,
          ),
        ),
      );

      expect(find.text('Selecione uma opção'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<TipoMoradia>));
      await tester.pumpAndSettle();

      for (final o in TipoMoradia.values) {
        expect(find.text(o.label), findsWidgets);
      }

      await tester.tap(find.text('Casa').last);
      await tester.pumpAndSettle();

      expect(selected, TipoMoradia.casa);
    });
  });

  group('DssSingleChoiceQuestion — lista vertical com rádio', () {
    testWidgets('3+ opções verticais, rádio à esquerda, seleção única',
        (tester) async {
      final controller = AlimentacaoController();

      await tester.pumpWidget(
        _wrap(
          Observer(
            builder: (_) => DssSingleChoiceQuestion<RefeicoesPorDia>(
              title: 'Quantas refeições completas você faz por dia?',
              value: controller.refeicoesPorDia,
              options: RefeicoesPorDia.values,
              labelOf: (e) => e.label,
              onChanged: controller.setRefeicoesPorDia,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      for (final o in RefeicoesPorDia.values) {
        expect(find.text(o.label), findsOneWidget);
      }

      await tester.tap(find.text('3 refeições'));
      await tester.pump();

      expect(controller.refeicoesPorDia, RefeicoesPorDia.tres);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });
  });

  group('DssMultiChoiceQuestion — cartões retangulares', () {
    testWidgets('multi-seleção independente preserva A e B selecionados',
        (tester) async {
      final controller = SaudeController();

      await tester.pumpWidget(
        _wrap(
          DssMultiChoiceQuestion<ServicoPreNatal>(
            title: 'Quais serviços de pré-natal você utiliza?',
            options: ServicoPreNatal.values,
            selected: controller.servicosPreNatal,
            labelOf: (s) => s.label,
            onToggle: controller.toggleServicoPreNatal,
            exclusive: ServicoPreNatal.nenhumDosListados,
          ),
        ),
      );

      await tester.tap(find.text('Consulta médica regular'));
      await tester.pump();
      await tester.tap(find.text('Grupo de gestantes'));
      await tester.pump();

      expect(
        controller.servicosPreNatal,
        containsAll([
          ServicoPreNatal.consultaMedica,
          ServicoPreNatal.grupoGestantes,
        ]),
      );
      expect(_optionOf(tester, 'Consulta médica regular').selected, isTrue);
      expect(_optionOf(tester, 'Grupo de gestantes').selected, isTrue);
    });
  });

  group('Opção exclusiva — separador "ou"', () {
    testWidgets('separador "ou" precede a opção exclusiva e a marca como tal',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          DssMultiChoiceQuestion<ServicoPreNatal>(
            title: 'Quais serviços de pré-natal você utiliza?',
            options: ServicoPreNatal.values,
            selected: ObservableList<ServicoPreNatal>(),
            labelOf: (s) => s.label,
            onToggle: (_) {},
            exclusive: ServicoPreNatal.nenhumDosListados,
          ),
        ),
      );

      expect(find.text('ou'), findsOneWidget);

      expect(_optionOf(tester, 'Consulta médica regular').exclusive, isFalse);
      expect(_optionOf(tester, 'Nenhum dos serviços listados').exclusive, isTrue);
    });
  });

  group('"Outro" como opção normal', () {
    testWidgets('não gera campo de texto livre e seleciona como opção normal',
        (tester) async {
      final controller = SaudeController();

      await tester.pumpWidget(
        _wrap(
          DssMultiChoiceQuestion<DificuldadeSaude>(
            title: 'Quais dificuldades você enfrenta para acessar a saúde?',
            options: DificuldadeSaude.values,
            selected: controller.dificuldadesSaude,
            labelOf: (d) => d.label,
            onToggle: controller.toggleDificuldadeSaude,
            exclusive: DificuldadeSaude.semDificuldades,
          ),
        ),
      );

      // "Outro" é uma opção normal (DssMultiOption), NÃO um campo de texto
      // livre — evita alterar o schema 1.13.
      expect(_optionOf(tester, 'Outro').exclusive, isFalse);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);

      await tester.tap(find.text('Outro'));
      await tester.pump();

      expect(controller.dificuldadesSaude, contains(DificuldadeSaude.outro));
      expect(_optionOf(tester, 'Outro').selected, isTrue);
    });
  });
}
