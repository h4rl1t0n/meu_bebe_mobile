import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/ui/theme/app_theme.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/saude_options.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/saude/saude_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/trabalho/trabalho_controller.dart';
import 'package:meu_bebe/app/modules/formulario/widgets/dss_question.dart';

/// Testes de REATIVIDADE MobX (FASE 9G-FIX3).
///
/// Provam que o tap num `FilterChip` produz `ação MobX → estado reativo muda →
/// Observer detecta → chip redesenha imediatamente`, SEM depender de responder
/// outra pergunta. O `DssMultiChoiceQuestion` é testado SEM `Observer` externo
/// — a reação vem do `Observer` INTERNO adicionado no fix (o `Observer` da aba
/// lê apenas a referência do ObservableList, nunca o conteúdo).

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

FilterChip _chipOf(WidgetTester tester, String label) {
  return tester.widget<FilterChip>(
    find.widgetWithText(FilterChip, label),
  );
}

Widget _servicosQuestion(SaudeController controller) {
  return DssMultiChoiceQuestion<ServicoPreNatal>(
    title: 'Quais serviços de pré-natal você utiliza?',
    options: ServicoPreNatal.values,
    selected: controller.servicosPreNatal,
    labelOf: (s) => s.label,
    onToggle: controller.toggleServicoPreNatal,
    required: true,
    showError: controller.showErrors,
    exclusive: ServicoPreNatal.nenhumDosListados,
  );
}

void main() {
  group('DssMultiChoiceQuestion — reatividade imediata dos chips', () {
    testWidgets('tap no chip A seleciona imediatamente (sem responder outra pergunta)',
        (tester) async {
      final controller = SaudeController();
      controller.setShowErrors(true);

      await tester.pumpWidget(_wrap(_servicosQuestion(controller)));

      expect(_chipOf(tester, 'Consulta médica regular').selected, isFalse);
      expect(find.text('Campo obrigatório'), findsOneWidget);

      await tester.tap(find.text('Consulta médica regular'));
      await tester.pump();

      // Chip A redesenhado imediatamente + erro inline some no mesmo frame.
      expect(_chipOf(tester, 'Consulta médica regular').selected, isTrue);
      expect(find.text('Campo obrigatório'), findsNothing);
      expect(controller.servicosPreNatal, contains(ServicoPreNatal.consultaMedica));
    });

    testWidgets('A + B permanecem ambos selecionados', (tester) async {
      final controller = SaudeController();

      await tester.pumpWidget(_wrap(_servicosQuestion(controller)));

      await tester.tap(find.text('Consulta médica regular'));
      await tester.pump();
      await tester.tap(find.text('Grupo de gestantes'));
      await tester.pump();

      expect(_chipOf(tester, 'Consulta médica regular').selected, isTrue);
      expect(_chipOf(tester, 'Grupo de gestantes').selected, isTrue);
      expect(
        controller.servicosPreNatal,
        containsAll([ServicoPreNatal.consultaMedica, ServicoPreNatal.grupoGestantes]),
      );
    });

    testWidgets('selecionar a exclusiva desmarca as demais imediatamente',
        (tester) async {
      final controller = SaudeController();

      await tester.pumpWidget(_wrap(_servicosQuestion(controller)));

      await tester.tap(find.text('Consulta médica regular'));
      await tester.pump();
      await tester.tap(find.text('Nenhum dos serviços listados'));
      await tester.pump();

      expect(_chipOf(tester, 'Nenhum dos serviços listados').selected, isTrue);
      expect(_chipOf(tester, 'Consulta médica regular').selected, isFalse);
      expect(controller.servicosPreNatal, [ServicoPreNatal.nenhumDosListados]);
    });

    testWidgets('tap de novo na exclusiva a remove imediatamente', (tester) async {
      final controller = SaudeController();

      await tester.pumpWidget(_wrap(_servicosQuestion(controller)));

      await tester.tap(find.text('Nenhum dos serviços listados'));
      await tester.pump();
      expect(_chipOf(tester, 'Nenhum dos serviços listados').selected, isTrue);

      await tester.tap(find.text('Nenhum dos serviços listados'));
      await tester.pump();

      expect(_chipOf(tester, 'Nenhum dos serviços listados').selected, isFalse);
      expect(controller.servicosPreNatal, isEmpty);
    });

    testWidgets('tap de novo numa opção normal a desmarca imediatamente',
        (tester) async {
      final controller = SaudeController();

      await tester.pumpWidget(_wrap(_servicosQuestion(controller)));

      await tester.tap(find.text('Consulta médica regular'));
      await tester.pump();
      await tester.tap(find.text('Consulta médica regular'));
      await tester.pump();

      expect(_chipOf(tester, 'Consulta médica regular').selected, isFalse);
      expect(controller.servicosPreNatal, isEmpty);
    });
  });

  group('DssBinaryQuestion — reação imediata via Observer', () {
    testWidgets('"Não" → "Sim" muda a seleção imediatamente e o erro some',
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

      expect(controller.cadastradaUBS, isNull);
      expect(find.text('Campo obrigatório'), findsOneWidget);

      await tester.tap(find.text('Não'));
      await tester.pump();

      expect(controller.cadastradaUBS, isFalse);
      expect(find.text('Campo obrigatório'), findsNothing);

      await tester.tap(find.text('Sim'));
      await tester.pump();

      expect(controller.cadastradaUBS, isTrue);
      expect(find.text('Campo obrigatório'), findsNothing);
    });
  });

  group('Campo condicional — aparece/some imediatamente', () {
    testWidgets('empregado == true revela o bloco; == false o oculta',
        (tester) async {
      final controller = TrabalhoController();

      await tester.pumpWidget(
        _wrap(
          Observer(
            builder: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DssBinaryQuestion(
                  title: 'Você está trabalhando atualmente?',
                  value: controller.empregado,
                  onChanged: controller.setEmpregado,
                  required: true,
                  showError: controller.showErrors,
                ),
                if (controller.empregado == true) const Text('BLOCO_EMPREGADA'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('BLOCO_EMPREGADA'), findsNothing);

      await tester.tap(find.text('Sim'));
      await tester.pump();

      expect(find.text('BLOCO_EMPREGADA'), findsOneWidget);

      await tester.tap(find.text('Não'));
      await tester.pump();

      expect(find.text('BLOCO_EMPREGADA'), findsNothing);
    });
  });
}
