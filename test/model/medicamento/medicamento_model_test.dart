import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/medicamento/medicamento_model.dart';

MedicamentoModel _med({
  String id = 'm1',
  String nome = 'Ácido fólico',
  String dose = '5mg',
  String frequencia = '1 vez ao dia',
}) {
  return MedicamentoModel(id: id, nome: nome, dose: dose, frequencia: frequencia);
}

void main() {
  group('MedicamentoModel.tryParse', () {
    test('parse válido (id UUID, nome, dose, frequencia)', () {
      final m = MedicamentoModel.tryParse({
        'id': 'uuid-med-1',
        'nome': 'Ácido fólico',
        'dose': '5mg',
        'frequencia': '1 vez ao dia',
        'created_at': '2026-08-10T00:00:00Z',
      });

      expect(m, isNotNull);
      expect(m!.id, 'uuid-med-1');
      expect(m.nome, 'Ácido fólico');
      expect(m.dose, '5mg');
      expect(m.frequencia, '1 vez ao dia');
    });

    test('campo obrigatório ausente ou tipo inválido → null', () {
      expect(
        MedicamentoModel.tryParse({
          'id': 'm1',
          'nome': 'x',
          'dose': 'y',
          // sem 'frequencia'
        }),
        isNull,
      );
      expect(
        MedicamentoModel.tryParse({
          'id': 1, // id não-string
          'nome': 'x',
          'dose': 'y',
          'frequencia': 'z',
        }),
        isNull,
      );
      expect(
        MedicamentoModel.tryParse({
          'id': 'm1',
          'nome': 'x',
          'dose': 123, // dose não-string
          'frequencia': 'z',
        }),
        isNull,
      );
    });

    test('não-map → null', () {
      expect(MedicamentoModel.tryParse(null), isNull);
      expect(MedicamentoModel.tryParse('abc'), isNull);
      expect(MedicamentoModel.tryParse(42), isNull);
    });
  });

  group('MedicamentoModel.toWriteJson', () {
    test('envia apenas campos editáveis (IDs e timestamps proibidos)', () {
      final json = _med().toWriteJson();

      expect(json, {
        'nome': 'Ácido fólico',
        'dose': '5mg',
        'frequencia': '1 vez ao dia',
      });

      // IDs proibidos: id, gestacao_id, user_id, gestante_id, timestamps.
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('gestacao_id'), isFalse);
      expect(json.containsKey('user_id'), isFalse);
      expect(json.containsKey('gestante_id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });

    test('frequencia é texto livre (não HH:mm)', () {
      expect(_med(frequencia: '6 em 6 horas').toWriteJson()['frequencia'],
          '6 em 6 horas');
    });
  });
}
