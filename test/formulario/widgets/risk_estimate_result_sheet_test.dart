import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/ui/theme/app_theme.dart';
import 'package:meu_bebe/app/modules/formulario/models/risk_estimate/risk_estimate_response_model.dart';
import 'package:meu_bebe/app/modules/formulario/widgets/risk_estimate_result_sheet.dart';

const _notice =
    'Estimativa estatística experimental baseada em dados sintéticos; não '
    'constitui diagnóstico médico nem certeza de descontinuidade do pré-natal.';

const _estimate = RiskEstimateResponseModel(
  result: RiskEstimateResultModel(
    target: 'descontinuou_pre_natal',
    probability: 0.238,
  ),
  model: RiskEstimateModelMetadata(
    name: 'random_forest',
    schemaVersion: '1.13',
    rawFeatureCount: 34,
    transformedFeatureCount: 96,
  ),
  notice: _notice,
);

RiskEstimateResponseModel _withProbability(double probability) {
  return RiskEstimateResponseModel(
    result: RiskEstimateResultModel(
      target: 'descontinuou_pre_natal',
      probability: probability,
    ),
    model: const RiskEstimateModelMetadata(
      name: 'random_forest',
      schemaVersion: '1.13',
      rawFeatureCount: 34,
      transformedFeatureCount: 96,
    ),
    notice: _notice,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('formatProbabilityPercent', () {
    test('0.238 → "23,8%"', () {
      expect(formatProbabilityPercent(0.238), '23,8%');
    });

    test('0.0 → "0,0%"', () {
      expect(formatProbabilityPercent(0.0), '0,0%');
    });

    test('1.0 → "100,0%"', () {
      expect(formatProbabilityPercent(1.0), '100,0%');
    });

    test('0.321987654321 → "32,2%" (arredondamento só visual)', () {
      expect(formatProbabilityPercent(0.321987654321), '32,2%');
    });

    test('não muta o double original', () {
      final model = _withProbability(0.321987654321);
      final original = model.result.probability;

      formatProbabilityPercent(original);

      expect(model.result.probability, original);
      expect(model.result.probability, 0.321987654321);
    });
  });

  group('RiskEstimateResultContent', () {
    testWidgets('mostra o percentual e o rótulo semântico', (tester) async {
      await tester.pumpWidget(
        _wrap(const RiskEstimateResultContent(estimate: _estimate)),
      );

      expect(find.text('23,8%'), findsOneWidget);
      expect(
        find.text(
          'Probabilidade estimada de descontinuidade do acompanhamento pré-natal',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mostra o notice recebido (não hardcoded)', (tester) async {
      const customNotice = 'Aviso metodológico customizado para teste.';
      final estimate = RiskEstimateResponseModel(
        result: const RiskEstimateResultModel(
          target: 'descontinuou_pre_natal',
          probability: 0.238,
        ),
        model: const RiskEstimateModelMetadata(
          name: 'random_forest',
          schemaVersion: '1.13',
          rawFeatureCount: 34,
          transformedFeatureCount: 96,
        ),
        notice: customNotice,
      );

      await tester.pumpWidget(
        _wrap(RiskEstimateResultContent(estimate: estimate)),
      );

      expect(find.text(customNotice), findsOneWidget);
    });

    testWidgets('não apresenta classificação nem juízo de desfecho', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const RiskEstimateResultContent(estimate: _estimate)),
      );

      // "baixo/médio/alto risco", "vai/não vai desistir", "sem risco".
      expect(find.textContaining('risco'), findsNothing);
      expect(find.textContaining('desistir'), findsNothing);
      // Nenhuma palavra "certeza" isolada (o notice usa a negação).
      expect(find.text('certeza'), findsNothing);
    });

    testWidgets('0% mostra "0,0%" e o notice, sem "sem risco"', (tester) async {
      final estimate = _withProbability(0.0);

      await tester.pumpWidget(
        _wrap(RiskEstimateResultContent(estimate: estimate)),
      );

      expect(find.text('0,0%'), findsOneWidget);
      expect(find.text(estimate.notice), findsOneWidget);
      expect(find.text('sem risco'), findsNothing);
    });

    testWidgets('100% mostra "100,0%" e o notice, sem "certeza"', (
      tester,
    ) async {
      final estimate = _withProbability(1.0);

      await tester.pumpWidget(
        _wrap(RiskEstimateResultContent(estimate: estimate)),
      );

      expect(find.text('100,0%'), findsOneWidget);
      expect(find.text(estimate.notice), findsOneWidget);
      expect(find.text('certeza'), findsNothing);
    });

    testWidgets('exibe fatores determinantes (XAI) quando presentes', (
      tester,
    ) async {
      final estimate = RiskEstimateResponseModel(
        result: const RiskEstimateResultModel(
          target: 'descontinuou_pre_natal',
          probability: 0.35,
        ),
        model: const RiskEstimateModelMetadata(
          name: 'random_forest',
          schemaVersion: '1.13',
          rawFeatureCount: 34,
          transformedFeatureCount: 96,
        ),
        notice: _notice,
        factors: const [
          RiskFactorContributionModel(
            feature: 'renda_familiar_sm',
            label: 'Renda Familiar',
            contribution: 0.12,
            direction: 'increases_risk',
            description: 'Menor margem de estabilidade financeira.',
          ),
          RiskFactorContributionModel(
            feature: 'escolaridade',
            label: 'Escolaridade',
            contribution: -0.08,
            direction: 'decreases_risk',
            description: 'Maior grau de instrução atua favoravelmente.',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(RiskEstimateResultContent(estimate: estimate)),
      );

      expect(find.text('Fatores determinantes (IA Explicável)'), findsOneWidget);
      expect(find.text('Renda Familiar'), findsOneWidget);
      expect(find.text('Menor margem de estabilidade financeira.'), findsOneWidget);
      expect(find.text('Atenção (+12.0%)'), findsOneWidget);

      expect(find.text('Escolaridade'), findsOneWidget);
      expect(find.text('Maior grau de instrução atua favoravelmente.'), findsOneWidget);
      expect(find.text('Proteção (-8.0%)'), findsOneWidget);
    });
  });

  group('showRiskEstimateResultSheet', () {
    testWidgets('botão "Entendi" fecha o sheet de resultado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () =>
                      showRiskEstimateResultSheet(context, _estimate),
                  child: const Text('abrir resultado'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir resultado'));
      await tester.pumpAndSettle();

      expect(find.text('23,8%'), findsOneWidget);
      expect(find.text('Entendi'), findsOneWidget);

      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();

      expect(find.text('Entendi'), findsNothing);
      expect(find.text('23,8%'), findsNothing);
    });
  });
}
