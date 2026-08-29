import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/consulta/consulta_model.dart';

void main() {
  group('ConsultaModel.tryParse', () {
    test('parse válido', () {
      final c = ConsultaModel.tryParse({
        'id': 'c1',
        'titulo': 'Pré-natal',
        'data_consulta': '2025-11-01',
        'descricao': 'Rotina',
        'created_at': '2025-11-01T00:00:00Z',
        'updated_at': '2025-11-01T00:00:00Z',
      });

      expect(c, isNotNull);
      expect(c!.id, 'c1');
      expect(c.titulo, 'Pré-natal');
      expect(c.dataConsulta, '2025-11-01');
      expect(c.descricao, 'Rotina');
    });

    test('campo obrigatório com tipo inválido → null', () {
      expect(
        ConsultaModel.tryParse({
          'id': 1,
          'titulo': 'x',
          'data_consulta': 'y',
          'descricao': 'z',
        }),
        isNull,
      );
      expect(
        ConsultaModel.tryParse({
          'id': '1',
          'titulo': 2,
          'data_consulta': 'y',
          'descricao': 'z',
        }),
        isNull,
      );
      expect(
        ConsultaModel.tryParse({
          'id': '1',
          'titulo': 'x',
          'data_consulta': null,
          'descricao': 'z',
        }),
        isNull,
      );
      expect(
        ConsultaModel.tryParse({
          'id': '1',
          'titulo': 'x',
          'data_consulta': 'y',
          'descricao': 4,
        }),
        isNull,
      );
    });

    test('não-map → null', () {
      expect(ConsultaModel.tryParse(null), isNull);
      expect(ConsultaModel.tryParse('abc'), isNull);
      expect(ConsultaModel.tryParse([1, 2, 3]), isNull);
    });
  });

  group('ConsultaModel.toWriteJson', () {
    test('envia apenas campos editáveis (sem id/gestacao_id/timestamps)', () {
      const c = ConsultaModel(
        id: 'c1',
        titulo: 'T',
        dataConsulta: '2025-11-01',
        descricao: 'D',
      );

      final json = c.toWriteJson();

      expect(json, {'titulo': 'T', 'data_consulta': '2025-11-01', 'descricao': 'D'});
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('gestacao_id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
      expect(json.containsKey('user_id'), isFalse);
      expect(json.containsKey('gestante_id'), isFalse);
    });
  });
}
