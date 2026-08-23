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

    test('setSituacaoEstudosGestacao codifica os três códigos canônicos', () {
      final controller = EducacaoController();

      controller.setSituacaoEstudosGestacao(SituacaoEstudosGestacao.naoEstudava);
      expect(controller.buildEducacaoData().situacaoEstudosGestacao, 'nao_estudava');

      controller.setSituacaoEstudosGestacao(SituacaoEstudosGestacao.naoInterrompeu);
      expect(controller.buildEducacaoData().situacaoEstudosGestacao, 'nao_interrompeu');

      controller.setSituacaoEstudosGestacao(SituacaoEstudosGestacao.interrompeu);
      expect(controller.buildEducacaoData().situacaoEstudosGestacao, 'interrompeu');
    });

    test('toggleDificuldade preserva múltipla escolha como lista de códigos', () {
      final controller = EducacaoController();

      controller.toggleDificuldade(DificuldadeEducacao.faltaDinheiro);
      controller.toggleDificuldade(DificuldadeEducacao.distancia);

      expect(controller.buildEducacaoData().dificuldadesEducacao, ['falta_dinheiro', 'distancia']);

      controller.toggleDificuldade(DificuldadeEducacao.faltaDinheiro);
      expect(controller.buildEducacaoData().dificuldadesEducacao, ['distancia']);
    });

    test('setEscolaridade codifica superior_incompleto/superior_completo', () {
      final controller = EducacaoController();
      controller.setEscolaridade(Escolaridade.superiorIncompleto);
      expect(controller.buildEducacaoData().escolaridade, 'superior_incompleto');

      controller.setEscolaridade(Escolaridade.superiorCompleto);
      expect(controller.buildEducacaoData().escolaridade, 'superior_completo');
    });

    test('sem_dificuldades é mutuamente exclusiva: selecioná-la limpa as demais', () {
      final controller = EducacaoController();
      controller.toggleDificuldade(DificuldadeEducacao.faltaDinheiro);
      controller.toggleDificuldade(DificuldadeEducacao.distancia);

      controller.toggleDificuldade(DificuldadeEducacao.semDificuldades);

      expect(controller.buildEducacaoData().dificuldadesEducacao, ['sem_dificuldades']);
    });

    test('selecionar outra dificuldade remove sem_dificuldades', () {
      final controller = EducacaoController();
      controller.toggleDificuldade(DificuldadeEducacao.semDificuldades);

      controller.toggleDificuldade(DificuldadeEducacao.faltaTransporte);

      final codes = controller.buildEducacaoData().dificuldadesEducacao;
      expect(codes, contains('falta_transporte'));
      expect(codes, isNot(contains('sem_dificuldades')));
    });

    test('desmarcar sem_dificuldades esvazia a lista (permite deseleção)', () {
      final controller = EducacaoController();
      controller.toggleDificuldade(DificuldadeEducacao.semDificuldades);
      expect(controller.buildEducacaoData().dificuldadesEducacao, ['sem_dificuldades']);

      controller.toggleDificuldade(DificuldadeEducacao.semDificuldades);
      expect(controller.buildEducacaoData().dificuldadesEducacao, isEmpty);
    });

    test('campos começam null e são serializados como null (não respondido)', () {
      final controller = EducacaoController();

      final data = controller.buildEducacaoData();
      expect(data.estuda, isNull);
      expect(data.situacaoEstudosGestacao, isNull);
      expect(data.entendeOrientacoes, isNull);
      expect(data.fezCursoQualificacaoProfissional, isNull);
    });

    test('booleanos e situação preservam valores explícitos no buildEducacaoData', () {
      final controller = EducacaoController();
      controller.setEstuda(true);
      controller.setSituacaoEstudosGestacao(SituacaoEstudosGestacao.naoInterrompeu);
      controller.setEntendeOrientacoes(true);
      controller.setFezCursoQualificacaoProfissional(false);

      final data = controller.buildEducacaoData();
      expect(data.estuda, isTrue);
      expect(data.situacaoEstudosGestacao, 'nao_interrompeu');
      expect(data.entendeOrientacoes, isTrue);
      expect(data.fezCursoQualificacaoProfissional, isFalse);
    });

    test('isValid exige escolaridade, situação, booleanos e ao menos uma dificuldade', () {
      final controller = EducacaoController();
      expect(controller.isValid, isFalse);

      controller.setEscolaridade(Escolaridade.medioCompleto);
      expect(controller.isValid, isFalse);

      controller.setEstuda(true);
      expect(controller.isValid, isFalse);

      controller.setSituacaoEstudosGestacao(SituacaoEstudosGestacao.naoEstudava);
      expect(controller.isValid, isFalse);

      controller.setEntendeOrientacoes(true);
      expect(controller.isValid, isFalse);

      controller.setFezCursoQualificacaoProfissional(false);
      expect(controller.isValid, isFalse); // dificuldades ainda vazia

      controller.toggleDificuldade(DificuldadeEducacao.semDificuldades);
      expect(controller.isValid, isTrue);
    });
  });
}
