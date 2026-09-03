import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/ui/theme/app_theme.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/current_gestation/widgets/current_gestation_card.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/history/widgets/history_card.dart';

/// Testes de regressão da FASE 9J-FIX1: os dois campos que estavam hardcoded
/// como `content: ''` no "Plano de parto detalhado" devem exibir os dados reais
/// vindos da API.
///
///  - "História das gestações anteriores" → contadores do histórico obstétrico.
///  - "Sobre a minha gravidez atual"     → pré-natal (local/profissional/contato).
///
/// Fallback "Não informado" quando tudo está vazio/nulo. Nenhum campo permanece
/// com `content: ''` (verificado no grep de código, além destes testes).

Widget _mount(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryCard — "História das gestações anteriores"', () {
    testWidgets('preenchido → exibe o resumo real dos contadores',
        (tester) async {
      await tester.pumpWidget(
        _mount(
          const HistoryCard(
            pregnancyNumber: 2,
            givenBirthNumber: 1,
            abortionsNumber: 0,
          ),
        ),
      );

      expect(find.text('2 gestações, 1 parto, 0 abortos'), findsOneWidget);
    });

    testWidgets('todos nulos → "Não informado"', (tester) async {
      await tester.pumpWidget(
        _mount(
          const HistoryCard(
            pregnancyNumber: null,
            givenBirthNumber: null,
            abortionsNumber: null,
          ),
        ),
      );

      expect(find.text('Não informado'), findsOneWidget);
      expect(find.text('2 gestações, 1 parto, 0 abortos'), findsNothing);
    });

    testWidgets('contador parcial → lista somente os preenchidos',
        (tester) async {
      await tester.pumpWidget(
        _mount(
          const HistoryCard(
            pregnancyNumber: 2,
            givenBirthNumber: null,
            abortionsNumber: 0,
          ),
        ),
      );

      expect(find.text('2 gestações, 0 abortos'), findsOneWidget);
    });
  });

  group('CurrentGestationCard — "Sobre a minha gravidez atual"', () {
    testWidgets('preenchido → exibe o resumo real do pré-natal',
        (tester) async {
      await tester.pumpWidget(
        _mount(
          const CurrentGestationCard(
            lastMenstrualPeriod: '2026-01-10',
            firstUltrasound: '2025-12-01',
            localPreNatal: 'UBS Centro',
            profissionalPreNatal: 'Dra. Ana',
            contatoLocalPreNatal: '(92) 99999-0000',
          ),
        ),
      );

      expect(
        find.text('Local: UBS Centro • Profissional: Dra. Ana • Contato: (92) 99999-0000'),
        findsOneWidget,
      );
    });

    testWidgets('pré-natal nulo → "Não informado"', (tester) async {
      await tester.pumpWidget(
        _mount(
          const CurrentGestationCard(
            lastMenstrualPeriod: '2026-01-10',
            firstUltrasound: '2025-12-01',
            localPreNatal: null,
            profissionalPreNatal: null,
            contatoLocalPreNatal: null,
          ),
        ),
      );

      // O único "Não informado" vem do resumo do pré-natal (as datas são
      // preenchidas acima, então não contribuem com o fallback).
      expect(find.text('Não informado'), findsOneWidget);
    });

    testWidgets('pré-natal vazio ("") → "Não informado"', (tester) async {
      await tester.pumpWidget(
        _mount(
          const CurrentGestationCard(
            lastMenstrualPeriod: '2026-01-10',
            firstUltrasound: '2025-12-01',
            localPreNatal: '',
            profissionalPreNatal: '',
            contatoLocalPreNatal: '',
          ),
        ),
      );

      expect(find.text('Não informado'), findsOneWidget);
    });
  });
}
