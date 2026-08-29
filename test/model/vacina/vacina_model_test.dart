import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/vacina/vacina_model.dart';

void main() {
  group('VacinaModel.tryParse', () {
    test('parse válido (id UUID, nome canônico, aplicada bool)', () {
      final v = VacinaModel.tryParse({
        'id': 'uuid-real-abc',
        'nome': 'dTpa',
        'aplicada': true,
        'created_at': '2026-08-10T00:00:00Z',
      });

      expect(v, isNotNull);
      expect(v!.id, 'uuid-real-abc');
      expect(v.nome, 'dTpa');
      expect(v.aplicada, isTrue);
    });

    test('campo obrigatório com tipo inválido → null', () {
      expect(
        VacinaModel.tryParse({
          'id': 'v1',
          'nome': 'dTpa',
          // sem 'aplicada'
        }),
        isNull,
      );
      expect(
        VacinaModel.tryParse({
          'id': 'v1',
          'nome': 'dTpa',
          'aplicada': 'sim', // não-bool
        }),
        isNull,
      );
      expect(
        VacinaModel.tryParse({
          'id': 1, // id não-string
          'nome': 'dTpa',
          'aplicada': false,
        }),
        isNull,
      );
    });

    test('não-map → null', () {
      expect(VacinaModel.tryParse(null), isNull);
      expect(VacinaModel.tryParse('abc'), isNull);
    });
  });

  group('VacinaModel.toWriteJson', () {
    test('envia apenas nome e aplicada (IDs e timestamps proibidos)', () {
      final json = const VacinaModel(
        id: 'uuid-real-abc',
        nome: 'dTpa',
        aplicada: true,
      ).toWriteJson();

      expect(json, {'nome': 'dTpa', 'aplicada': true});
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('gestacao_id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });
  });

  group('VacinaModel.copyWith', () {
    test('alterna aplicada preservando id e nome', () {
      const original = VacinaModel(id: 'uuid-x', nome: 'HB_1', aplicada: false);
      final flipped = original.copyWith(aplicada: true);

      expect(flipped.id, 'uuid-x');
      expect(flipped.nome, 'HB_1');
      expect(flipped.aplicada, isTrue);
      expect(original.aplicada, isFalse);
    });
  });
}
