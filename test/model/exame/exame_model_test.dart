import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/exame/exame_model.dart';

ExameModel _exame({
  String id = 'e1',
  String titulo = 'Ultrassom',
  String dataExame = '2025-10-01',
  String descricao = 'Obstétrico',
  String? categoria,
}) {
  return ExameModel(
    id: id,
    titulo: titulo,
    dataExame: dataExame,
    descricao: descricao,
    categoria: categoria,
  );
}

void main() {
  group('ExameModel.tryParse', () {
    test('parse válido com categoria', () {
      final e = ExameModel.tryParse({
        'id': 'e1',
        'titulo': 'Ultrassom',
        'data_exame': '2025-10-01',
        'descricao': 'Obstétrico',
        'categoria': 'ultrassom',
        'created_at': '2025-10-01T00:00:00Z',
      });

      expect(e, isNotNull);
      expect(e!.id, 'e1');
      expect(e.titulo, 'Ultrassom');
      expect(e.dataExame, '2025-10-01');
      expect(e.descricao, 'Obstétrico');
      expect(e.categoria, 'ultrassom');
    });

    test('categoria ausente ou tipo inválido → null', () {
      expect(
        ExameModel.tryParse({
          'id': 'e1',
          'titulo': 'x',
          'data_exame': '2025-10-01',
          'descricao': 'y',
        })!.categoria,
        isNull,
      );
      expect(
        ExameModel.tryParse({
          'id': 'e1',
          'titulo': 'x',
          'data_exame': '2025-10-01',
          'descricao': 'y',
          'categoria': 123,
        })!.categoria,
        isNull,
      );
    });

    test('campo obrigatório com tipo inválido → null', () {
      expect(
        ExameModel.tryParse({
          'id': 'e1',
          'titulo': 'x',
          'data_exame': null,
          'descricao': 'y',
        }),
        isNull,
      );
      expect(
        ExameModel.tryParse({
          'id': 1,
          'titulo': 'x',
          'data_exame': '2025-10-01',
          'descricao': 'y',
        }),
        isNull,
      );
    });

    test('não-map → null', () {
      expect(ExameModel.tryParse(null), isNull);
      expect(ExameModel.tryParse('abc'), isNull);
    });
  });

  group('ExameModel.toWriteJson', () {
    test('envia apenas campos editáveis (sem id/gestacao_id/timestamps)', () {
      final json = _exame().toWriteJson();

      expect(json, {
        'titulo': 'Ultrassom',
        'data_exame': '2025-10-01',
        'descricao': 'Obstétrico',
        'categoria': null,
      });
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('gestacao_id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });
  });

  group('ExameModel.firstUltrasoundDate', () {
    test('lista vazia → null', () {
      expect(ExameModel.firstUltrasoundDate([]), isNull);
    });

    test('sem exame de categoria ultrassom → null', () {
      expect(
        ExameModel.firstUltrasoundDate([
          _exame(categoria: 'sangue'),
          _exame(categoria: 'urina'),
        ]),
        isNull,
      );
    });

    test('um ultrassom → retorna a sua data', () {
      expect(
        ExameModel.firstUltrasoundDate([
          _exame(categoria: 'ultrassom', dataExame: '2025-10-01'),
        ]),
        '2025-10-01',
      );
    });

    test('múltiplos ultrassons → retorna a data mais antiga', () {
      expect(
        ExameModel.firstUltrasoundDate([
          _exame(categoria: 'ultrassom', dataExame: '2025-11-01'),
          _exame(categoria: 'ultrassom', dataExame: '2025-09-15'),
          _exame(categoria: 'ultrassom', dataExame: '2025-12-01'),
        ]),
        '2025-09-15',
      );
    });

    test('mistura categorias → considera apenas ultrassom', () {
      expect(
        ExameModel.firstUltrasoundDate([
          _exame(categoria: 'sangue', dataExame: '2025-01-01'),
          _exame(categoria: 'ultrassom', dataExame: '2025-10-01'),
        ]),
        '2025-10-01',
      );
    });

    test('categoria ultrassom difere por caixa → não conta', () {
      expect(
        ExameModel.firstUltrasoundDate([
          _exame(categoria: 'Ultrassom', dataExame: '2025-10-01'),
        ]),
        isNull,
      );
    });

    test(
      'fluxo real criado pela UI: sangue + 2 ultrassons → menor data de USG',
      () {
        expect(
          ExameModel.firstUltrasoundDate([
            _exame(categoria: 'sangue', dataExame: '2026-08-10'),
            _exame(categoria: 'ultrassom', dataExame: '2026-08-20'),
            _exame(categoria: 'ultrassom', dataExame: '2026-08-15'),
          ]),
          '2026-08-15',
        );
      },
    );

    test('removendo a 1ª USG, a próxima vira a primeira', () {
      expect(
        ExameModel.firstUltrasoundDate([
          _exame(categoria: 'ultrassom', dataExame: '2026-08-20'),
        ]),
        '2026-08-20',
      );
    });

    test('categoria null (não informada) → não conta como ultrassom', () {
      expect(
        ExameModel.firstUltrasoundDate([
          _exame(categoria: null, dataExame: '2026-08-01'),
          _exame(categoria: 'ultrassom', dataExame: '2026-08-20'),
        ]),
        '2026-08-20',
      );
      expect(ExameModel.firstUltrasoundDate([_exame(categoria: null)]), isNull);
    });
  });
}
