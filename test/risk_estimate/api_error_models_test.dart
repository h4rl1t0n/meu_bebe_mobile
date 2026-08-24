import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/risk_estimate/api_error_models.dart';

void main() {
  group('ApiErrorModel.tryParse (422 plano)', () {
    test('parseia code/message/details', () {
      final model = ApiErrorModel.tryParse({
        'code': 'VALIDATION_ERROR',
        'message': 'Requisição inválida',
        'details': [
          {
            'loc': ['body', 'educacao', 'escolaridade'],
            'msg': 'inválido',
            'type': 'enum',
          },
        ],
      });

      expect(model, isNotNull);
      expect(model!.code, 'VALIDATION_ERROR');
      expect(model.message, 'Requisição inválida');
      expect(model.details, hasLength(1));
      expect(model.details.first.loc, ['body', 'educacao', 'escolaridade']);
      expect(model.details.first.msg, 'inválido');
      expect(model.details.first.type, 'enum');
    });

    test('ignora detail malformado (parser defensivo)', () {
      final model = ApiErrorModel.tryParse({
        'code': 'VALIDATION_ERROR',
        'message': 'Requisição inválida',
        'details': [
          {
            'loc': ['body'],
            'msg': 'ok',
            'type': 'x',
          },
          'lixo',
          123,
        ],
      });

      expect(model, isNotNull);
      expect(model!.details, hasLength(1));
    });

    test('retorna null quando code/message ausentes', () {
      expect(ApiErrorModel.tryParse({'code': 'X'}), isNull);
      expect(ApiErrorModel.tryParse('não é mapa'), isNull);
    });
  });

  group('ApiErrorEnvelopeModel.tryParse (500/503 envelope)', () {
    test('parseia o envelope error', () {
      final model = ApiErrorEnvelopeModel.tryParse({
        'error': {
          'code': 'MODEL_NOT_READY',
          'message': 'Modelo de inferência indisponível.',
          'details': [],
        },
      });

      expect(model, isNotNull);
      expect(model!.error.code, 'MODEL_NOT_READY');
    });

    test('retorna null sem a chave error', () {
      expect(ApiErrorEnvelopeModel.tryParse({'code': 'X'}), isNull);
      expect(ApiErrorEnvelopeModel.tryParse({'error': 'não é mapa'}), isNull);
    });
  });
}
