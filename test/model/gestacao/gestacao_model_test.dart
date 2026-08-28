import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';

void main() {
  group('GestacaoModel.tryParse', () {
    test('parse válido do contrato FASE 8D (gestação ativa)', () {
      final g = GestacaoModel.tryParse({
        'id': 'gestacao-1',
        'data_ultima_menstruacao': '2025-11-01',
        'local_pre_natal': 'UBS Central',
        'profissional_pre_natal': 'Dra. Ana',
        'contato_local_pre_natal': '(92) 99999-0000',
        'ended_at': null,
      });

      expect(g, isNotNull);
      expect(g!.id, 'gestacao-1');
      expect(g.dataUltimaMenstruacao, '2025-11-01');
      expect(g.localPreNatal, 'UBS Central');
      expect(g.profissionalPreNatal, 'Dra. Ana');
      expect(g.contatoLocalPreNatal, '(92) 99999-0000');
      expect(g.endedAt, isNull);
    });

    test('retorna null se faltar id', () {
      expect(GestacaoModel.tryParse(null), isNull);
      expect(GestacaoModel.tryParse({'data_ultima_menstruacao': '2025-11-01'}), isNull);
      expect(GestacaoModel.tryParse({'id': 1}), isNull);
    });
  });
}
