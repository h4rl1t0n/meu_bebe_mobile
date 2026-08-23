import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/alimentacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/alimentacao/alimentacao_controller.dart';

void main() {
  group('AlimentacaoController', () {
    test('setRefeicoesPorDia codifica como código canônico', () {
      final controller = AlimentacaoController();
      controller.setRefeicoesPorDia(RefeicoesPorDia.tres);
      expect(controller.buildAlimentacaoData().refeicoesPorDia, 'tres');
    });

    test('toggleAlimento preserva múltipla escolha como lista de códigos', () {
      final controller = AlimentacaoController();
      controller.toggleAlimento(AlimentoConsumido.frutasVerduras);
      controller.toggleAlimento(AlimentoConsumido.carnes);

      expect(controller.buildAlimentacaoData().alimentosConsumidos, ['frutas_verduras', 'carnes']);

      controller.toggleAlimento(AlimentoConsumido.frutasVerduras);
      expect(controller.buildAlimentacaoData().alimentosConsumidos, ['carnes']);
    });

    test('nenhum_dos_listados é mutuamente exclusivo: selecioná-lo limpa as demais', () {
      final controller = AlimentacaoController();
      controller.toggleAlimento(AlimentoConsumido.frutasVerduras);
      controller.toggleAlimento(AlimentoConsumido.carnes);

      controller.toggleAlimento(AlimentoConsumido.nenhumDosListados);

      expect(controller.buildAlimentacaoData().alimentosConsumidos, ['nenhum_dos_listados']);
    });

    test('selecionar outro alimento remove nenhum_dos_listados', () {
      final controller = AlimentacaoController();
      controller.toggleAlimento(AlimentoConsumido.nenhumDosListados);

      controller.toggleAlimento(AlimentoConsumido.leiteDerivados);

      final codes = controller.buildAlimentacaoData().alimentosConsumidos;
      expect(codes, contains('leite_derivados'));
      expect(codes, isNot(contains('nenhum_dos_listados')));
    });

    test('desmarcar nenhum_dos_listados esvazia a lista (permite deseleção)', () {
      final controller = AlimentacaoController();
      controller.toggleAlimento(AlimentoConsumido.nenhumDosListados);
      expect(controller.buildAlimentacaoData().alimentosConsumidos, ['nenhum_dos_listados']);

      controller.toggleAlimento(AlimentoConsumido.nenhumDosListados);
      expect(controller.buildAlimentacaoData().alimentosConsumidos, isEmpty);
    });

    test('toggleFonteAlimento preserva múltiplas fontes como lista de códigos', () {
      final controller = AlimentacaoController();
      controller.toggleFonteAlimento(FonteAlimentos.supermercadoFeira);
      controller.toggleFonteAlimento(FonteAlimentos.hortaPropria);

      expect(controller.buildAlimentacaoData().fonteAlimentos, ['supermercado_feira', 'horta_propria']);

      controller.toggleFonteAlimento(FonteAlimentos.supermercadoFeira);
      expect(controller.buildAlimentacaoData().fonteAlimentos, ['horta_propria']);
    });

    test('campos começam null/vazio e são serializados como null/vazio', () {
      final controller = AlimentacaoController();

      final data = controller.buildAlimentacaoData();
      expect(data.refeicoesPorDia, isNull);
      expect(data.deixouDeComerFaltaDinheiro, isNull);
      expect(data.alimentosConsumidos, isEmpty);
      expect(data.fonteAlimentos, isEmpty);
      expect(data.mudancaAlimentacaoGestacao, isNull);
      expect(data.usaSuplementos, isNull);
      expect(data.avaliacaoAlimentacao, isNull);
    });

    test('booleanos preservam true/false explícitos', () {
      final controller = AlimentacaoController();
      controller.setDeixouComerFaltaDinheiro(true);
      controller.setMudancaAlimentacaoGestacao(false);
      controller.setUsaSuplementos(true);

      final data = controller.buildAlimentacaoData();
      expect(data.deixouDeComerFaltaDinheiro, isTrue);
      expect(data.mudancaAlimentacaoGestacao, isFalse);
      expect(data.usaSuplementos, isTrue);
    });

    test('isValid exige todas as perguntas respondidas', () {
      final controller = AlimentacaoController();
      expect(controller.isValid, isFalse);

      controller.setRefeicoesPorDia(RefeicoesPorDia.tres);
      expect(controller.isValid, isFalse);

      controller.setDeixouComerFaltaDinheiro(false);
      expect(controller.isValid, isFalse);

      controller.toggleAlimento(AlimentoConsumido.frutasVerduras);
      expect(controller.isValid, isFalse);

      controller.toggleFonteAlimento(FonteAlimentos.supermercadoFeira);
      expect(controller.isValid, isFalse);

      controller.setMudancaAlimentacaoGestacao(true);
      expect(controller.isValid, isFalse);

      controller.setUsaSuplementos(false);
      expect(controller.isValid, isFalse);

      controller.setAvaliacaoAlimentacao(AvaliacaoAlimentacao.boa);
      expect(controller.isValid, isTrue);
    });
  });
}
