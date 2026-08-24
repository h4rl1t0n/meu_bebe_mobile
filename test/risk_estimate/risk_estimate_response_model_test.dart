import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/risk_estimate/risk_estimate_response_model.dart';

void main() {
  Map<String, dynamic> ok() => {
    'result': {
      'target': 'descontinuou_pre_natal',
      'probability': 0.321987654321,
    },
    'model': {
      'name': 'random_forest',
      'schema_version': '1.13',
      'raw_feature_count': 34,
      'transformed_feature_count': 96,
    },
    'notice': 'Estimativa estatística experimental.',
  };

  group('RiskEstimateResponseModel.tryParse', () {
    test('parseia a resposta 200 completa', () {
      final model = RiskEstimateResponseModel.tryParse(ok());
      expect(model, isNotNull);
      expect(model!.result.target, 'descontinuou_pre_natal');
      expect(model.result.probability, 0.321987654321);
      expect(model.model.name, 'random_forest');
      expect(model.model.schemaVersion, '1.13');
      expect(model.model.rawFeatureCount, 34);
      expect(model.model.transformedFeatureCount, 96);
      expect(model.notice, 'Estimativa estatística experimental.');
    });

    test('probability é double, sem arredondamento', () {
      final model = RiskEstimateResponseModel.tryParse(ok());
      expect(model!.result.probability, isA<double>());
      expect(model.result.probability, 0.321987654321);
    });

    test('probability inteira (0/1) é convertida para double', () {
      final model = RiskEstimateResultModel.tryParse({
        'target': 'descontinuou_pre_natal',
        'probability': 1,
      });
      expect(model, isNotNull);
      expect(model!.probability, isA<double>());
      expect(model.probability, 1.0);
    });

    test('rejeita probability NaN', () {
      final model = RiskEstimateResultModel.tryParse({
        'target': 'descontinuou_pre_natal',
        'probability': double.nan,
      });
      expect(model, isNull);
    });

    test('rejeita probability infinita', () {
      final model = RiskEstimateResultModel.tryParse({
        'target': 'descontinuou_pre_natal',
        'probability': double.infinity,
      });
      expect(model, isNull);
    });

    test('rejeita probability fora de [0, 1]', () {
      expect(
        RiskEstimateResultModel.tryParse({'target': 'x', 'probability': 1.1}),
        isNull,
      );
      expect(
        RiskEstimateResultModel.tryParse({'target': 'x', 'probability': -0.1}),
        isNull,
      );
    });

    test('rejeita probability não numérica ou ausente', () {
      expect(
        RiskEstimateResultModel.tryParse({'target': 'x', 'probability': '0.5'}),
        isNull,
      );
      expect(RiskEstimateResultModel.tryParse({'target': 'x'}), isNull);
    });

    test('rejeita result/model/notice ausentes ou mal tipados', () {
      expect(RiskEstimateResponseModel.tryParse({}), isNull);
      expect(
        RiskEstimateResponseModel.tryParse({'result': null, 'model': null}),
        isNull,
      );
      expect(RiskEstimateResponseModel.tryParse('não é um mapa'), isNull);
    });
  });
}
