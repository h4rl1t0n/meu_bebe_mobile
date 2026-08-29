import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/vacina/vacina_catalogo.dart';

void main() {
  group('VacinaCatalogo', () {
    test('possui exatamente 7 itens (6 qualquer tempo + 1 dTpa)', () {
      expect(VacinaCatalogo.itens, hasLength(7));
      expect(VacinaCatalogo.itens.where((i) => !i.tpa), hasLength(6));
      expect(VacinaCatalogo.itens.where((i) => i.tpa), hasLength(1));
    });

    test('nomes canônicos são estáveis e únicos', () {
      final nomes = VacinaCatalogo.itens.map((i) => i.nome).toList();
      expect(nomes, [
        'HB_1',
        'HB_2',
        'HB_3',
        'dT_1',
        'dT_2',
        'dT_3',
        'dTpa',
      ]);
      expect(nomes.toSet(), hasLength(7));
    });

    test('item dTpa pertence ao grupo "20ª semana"', () {
      final dTpa = VacinaCatalogo.itens.singleWhere((i) => i.nome == 'dTpa');
      expect(dTpa.tpa, isTrue);
      expect(dTpa.titulo, contains('dTpa'));
      expect(dTpa.info, contains('Coqueluche'));
    });

    test('cada item tem nome/titulo/info não-vazios', () {
      for (final item in VacinaCatalogo.itens) {
        expect(item.nome, isNotEmpty);
        expect(item.titulo, isNotEmpty);
        expect(item.info, isNotEmpty);
      }
    });
  });
}
