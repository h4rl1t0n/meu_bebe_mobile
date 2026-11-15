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

    test('parseia resposta com fatores determinantes (XAI)', () {
      final json = ok();
      json['factors'] = [
        {
          'feature': 'renda_familiar_sm',
          'label': 'Renda Familiar',
          'contribution': 0.1245,
          'direction': 'increases_risk',
          'description': 'Valor informado associado a menor margem de estabilidade financeira.',
        },
        {
          'feature': 'escolaridade',
          'label': 'Escolaridade',
          'contribution': -0.0821,
          'direction': 'decreases_risk',
          'description': 'Maior grau de instrução atua como fator protetor de adesão.',
        },
      ];

      final model = RiskEstimateResponseModel.tryParse(json);
      expect(model, isNotNull);
      expect(model!.factors, isNotNull);
      expect(model.factors!.length, 2);

      final f1 = model.factors![0];
      expect(f1.feature, 'renda_familiar_sm');
      expect(f1.label, 'Renda Familiar');
      expect(f1.contribution, 0.1245);
      expect(f1.direction, 'increases_risk');
      expect(f1.increasesRisk, isTrue);
      expect(f1.decreasesRisk, isFalse);

      final f2 = model.factors![1];
      expect(f2.feature, 'escolaridade');
      expect(f2.label, 'Escolaridade');
      expect(f2.contribution, -0.0821);
      expect(f2.direction, 'decreases_risk');
      expect(f2.increasesRisk, isFalse);
      expect(f2.decreasesRisk, isTrue);
    });

    test('ignora fatores malformados defensivamente', () {
      final json = ok();
      json['factors'] = [
        {'feature': 'valido', 'label': 'Válido', 'contribution': 0.05, 'direction': 'increases_risk', 'description': 'Ok'},
        {'feature': 'sem_label', 'contribution': 0.05}, // malformado
        'não é mapa', // malformado
      ];

      final model = RiskEstimateResponseModel.tryParse(json);
      expect(model, isNotNull);
      expect(model!.factors, isNotNull);
      expect(model.factors!.length, 1);
      expect(model.factors!.first.feature, 'valido');
    });
  });
}
