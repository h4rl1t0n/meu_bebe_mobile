import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/educacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/educacao/educacao_controller.dart';

void main() {
  group('EducacaoController', () {
    test('setEscolaridade codifica como código canônico no buildEducacaoData', () {
      final controller = EducacaoController();

      controller.setEscolaridade(Escolaridade.medioCompleto);

      expect(controller.buildEducacaoData().escolaridade, 'medio_completo');
    });

    test('toggleDificuldade preserva múltipla escolha como lista de códigos', () {
      final controller = EducacaoController();

      controller.toggleDificuldade(DificuldadeEducacao.faltaDinheiro);
      controller.toggleDificuldade(DificuldadeEducacao.distancia);

      expect(controller.buildEducacaoData().dificuldadesEducacao, ['falta_dinheiro', 'distancia']);

      controller.toggleDificuldade(DificuldadeEducacao.faltaDinheiro);
      expect(controller.buildEducacaoData().dificuldadesEducacao, ['distancia']);
    });

    test('isValid exige escolaridade', () {
      final controller = EducacaoController();

      expect(controller.isValid, isFalse);

      controller.setEscolaridade(Escolaridade.superior);
      expect(controller.isValid, isTrue);
    });
  });
}
