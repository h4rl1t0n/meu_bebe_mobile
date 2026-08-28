import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/historico_obstetrico/historico_obstetrico_model.dart';

void main() {
  group('HistoricoObstetricoModel.tryParse', () {
    test('parse válido do contrato', () {
      final h = HistoricoObstetricoModel.tryParse({
        'id': 'hist-1',
        'pregnancy_number': 2,
        'given_birth_number': 1,
        'abortions_number': 0,
      });

      expect(h, isNotNull);
      expect(h!.id, 'hist-1');
      expect(h.pregnancyNumber, 2);
      expect(h.givenBirthNumber, 1);
      expect(h.abortionsNumber, 0);
    });

    test('campos opcionais nulos são preservados', () {
      final h = HistoricoObstetricoModel.tryParse({
        'id': 'hist-1',
        'pregnancy_number': null,
        'given_birth_number': null,
        'abortions_number': null,
      });

      expect(h, isNotNull);
      expect(h!.pregnancyNumber, isNull);
      expect(h.givenBirthNumber, isNull);
      expect(h.abortionsNumber, isNull);
    });

    test('id inválido ou ausente anula o parse', () {
      expect(HistoricoObstetricoModel.tryParse(null), isNull);
      expect(
        HistoricoObstetricoModel.tryParse({'pregnancy_number': 1}),
        isNull,
      );
      expect(HistoricoObstetricoModel.tryParse({'id': 1}), isNull);
    });

    test('contadores com tipo incorreto viram null (sem crash)', () {
      final h = HistoricoObstetricoModel.tryParse({
        'id': 'hist-1',
        'pregnancy_number': 'dois',
        'given_birth_number': 1.5,
        'abortions_number': 0,
      });

      expect(h, isNotNull);
      expect(h!.pregnancyNumber, isNull);
      expect(h.givenBirthNumber, isNull);
      expect(h.abortionsNumber, 0);
    });
  });

  group('HistoricoObstetricoModel.toWriteJson', () {
    test('payload envia apenas os 3 contadores', () {
      const h = HistoricoObstetricoModel(
        id: 'hist-1',
        pregnancyNumber: 2,
        givenBirthNumber: 1,
        abortionsNumber: 0,
      );

      expect(h.toWriteJson(), {
        'pregnancy_number': 2,
        'given_birth_number': 1,
        'abortions_number': 0,
      });
    });

    test('não envia id nem timestamps', () {
      const h = HistoricoObstetricoModel(id: 'hist-1');

      final json = h.toWriteJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });
  });
}
