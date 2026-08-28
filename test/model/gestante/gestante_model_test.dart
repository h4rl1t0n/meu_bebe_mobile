import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';

void main() {
  group('GestanteModel.tryParse', () {
    test('parse válido do contrato FASE 8D', () {
      final g = GestanteModel.tryParse({
        'id': 'gestante-1',
        'nome': 'Maria',
        'nome_social': 'Maria Silva',
        'data_nascimento': '1995-03-20',
        'cpf': '12345678901',
        'cns': '123456789012345',
      });

      expect(g, isNotNull);
      expect(g!.id, 'gestante-1');
      expect(g.nome, 'Maria');
      expect(g.nomeSocial, 'Maria Silva');
      expect(g.dataNascimento, '1995-03-20');
      expect(g.cpf, '12345678901');
      expect(g.cns, '123456789012345');
    });

    test('campos opcionais podem ser null', () {
      final g = GestanteModel.tryParse({
        'id': 'gestante-1',
        'nome': 'Maria',
        'nome_social': null,
        'data_nascimento': '1995-03-20',
        'cpf': null,
        'cns': null,
      });

      expect(g, isNotNull);
      expect(g!.nomeSocial, isNull);
      expect(g.cpf, isNull);
      expect(g.cns, isNull);
    });

    test('retorna null se faltar id/nome', () {
      expect(GestanteModel.tryParse(null), isNull);
      expect(GestanteModel.tryParse({'nome': 'Maria'}), isNull);
      expect(GestanteModel.tryParse({'id': 1, 'nome': 'Maria'}), isNull);
    });
  });

  group('GestanteModel.toWriteJson (POST/PUT full update)', () {
    test('envia apenas as chaves aceitas pelo backend', () {
      const g = GestanteModel(
        id: 'gestante-1',
        nome: 'Maria',
        nomeSocial: 'Maria Silva',
        dataNascimento: '1995-03-20',
        cpf: '12345678901',
        cns: '123456789012345',
      );

      final json = g.toWriteJson();

      expect(json.keys.toSet(), {
        'nome',
        'nome_social',
        'data_nascimento',
        'cpf',
        'cns',
      });
    });

    test('nunca envia id/user_id/timestamps (extra=forbid)', () {
      const g = GestanteModel(
        id: 'gestante-1',
        nome: 'Maria',
      );

      final json = g.toWriteJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('user_id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });
  });
}
