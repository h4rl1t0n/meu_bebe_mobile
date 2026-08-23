import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/alimentacao/alimentacao_model.dart';

void main() {
  group('AlimentacaoModel', () {
    test('toMap usa códigos canônicos e a nova chave de privação (sem chave legada)', () {
      const model = AlimentacaoModel(
        refeicoesPorDia: 'tres',
        deixouDeComerFaltaDinheiro: true,
        alimentosConsumidos: ['frutas_verduras', 'feijao_leguminosas'],
        fonteAlimentos: ['supermercado_feira', 'horta_propria'],
        mudancaAlimentacaoGestacao: false,
        usaSuplementos: true,
        avaliacaoAlimentacao: 'boa',
      );

      final map = model.toMap();

      expect(map['refeicoes_por_dia'], 'tres');
      expect(map['deixou_de_comer_falta_dinheiro'], isTrue);
      expect(map['alimentos_consumidos'], ['frutas_verduras', 'feijao_leguminosas']);
      expect(map['fonte_alimentos'], ['supermercado_feira', 'horta_propria']);
      expect(map['mudanca_alimentacao_gestacao'], isFalse);
      expect(map['usa_suplementos'], isTrue);
      expect(map['avaliacao_alimentacao'], 'boa');
      expect(map.containsKey('inseguranca_alimentar'), isFalse);
    });

    test('fromMap/toMap preserva listas e booleanos (round-trip)', () {
      const model = AlimentacaoModel(
        refeicoesPorDia: 'quatro_mais',
        deixouDeComerFaltaDinheiro: false,
        alimentosConsumidos: ['carnes', 'leite_derivados'],
        fonteAlimentos: ['cesta_basica', 'outro'],
        mudancaAlimentacaoGestacao: true,
        usaSuplementos: false,
        avaliacaoAlimentacao: 'ruim',
      );

      final restored = AlimentacaoModel.fromMap(model.toMap());

      expect(restored, model);
      expect(restored.alimentosConsumidos, ['carnes', 'leite_derivados']);
      expect(restored.fonteAlimentos, ['cesta_basica', 'outro']);
    });

    test('fromMap trata campos ausentes como null/vazio', () {
      final model = AlimentacaoModel.fromMap(const {});

      expect(model.refeicoesPorDia, isNull);
      expect(model.deixouDeComerFaltaDinheiro, isNull);
      expect(model.alimentosConsumidos, isEmpty);
      expect(model.fonteAlimentos, isEmpty);
      expect(model.mudancaAlimentacaoGestacao, isNull);
      expect(model.usaSuplementos, isNull);
      expect(model.avaliacaoAlimentacao, isNull);
    });

    test('empty() começa com tudo nulo e listas vazias', () {
      final model = AlimentacaoModel.empty();

      expect(model.refeicoesPorDia, isNull);
      expect(model.deixouDeComerFaltaDinheiro, isNull);
      expect(model.alimentosConsumidos, isEmpty);
      expect(model.fonteAlimentos, isEmpty);
      expect(model.mudancaAlimentacaoGestacao, isNull);
      expect(model.usaSuplementos, isNull);
      expect(model.avaliacaoAlimentacao, isNull);
    });

    test('true preserva true, false preserva false, null preserva null (round-trip)', () {
      const model = AlimentacaoModel(
        refeicoesPorDia: 'uma_duas',
        deixouDeComerFaltaDinheiro: true,
        alimentosConsumidos: ['frutas_verduras'],
        fonteAlimentos: ['supermercado_feira'],
        mudancaAlimentacaoGestacao: null,
        usaSuplementos: false,
        avaliacaoAlimentacao: 'regular',
      );

      final restored = AlimentacaoModel.fromMap(model.toMap());

      expect(restored.deixouDeComerFaltaDinheiro, isTrue);
      expect(restored.mudancaAlimentacaoGestacao, isNull);
      expect(restored.usaSuplementos, isFalse);
      expect(restored, model);
    });

    test('nenhum_dos_listados é preservado como código canônico', () {
      const model = AlimentacaoModel(alimentosConsumidos: ['nenhum_dos_listados']);

      expect(model.toMap()['alimentos_consumidos'], ['nenhum_dos_listados']);
      expect(AlimentacaoModel.fromMap(model.toMap()), model);
    });
  });
}
