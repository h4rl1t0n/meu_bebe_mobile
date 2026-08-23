import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/saude_options.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/saude/saude_controller.dart';

void main() {
  group('SaudeController', () {
    test('toggleDificuldadeSaude codifica como lista de códigos canônicos no buildSaudeData', () {
      final controller = SaudeController();
      controller.toggleDificuldadeSaude(DificuldadeSaude.faltaTransporte);
      controller.toggleDificuldadeSaude(DificuldadeSaude.demoraAtendimento);

      expect(controller.buildSaudeData().dificuldadesSaude, ['falta_transporte', 'demora_atendimento']);
    });

    test('sem_dificuldades é mutuamente exclusiva: selecioná-la limpa as demais', () {
      final controller = SaudeController();
      controller.toggleDificuldadeSaude(DificuldadeSaude.faltaTransporte);
      controller.toggleDificuldadeSaude(DificuldadeSaude.demoraAtendimento);

      controller.toggleDificuldadeSaude(DificuldadeSaude.semDificuldades);

      expect(controller.buildSaudeData().dificuldadesSaude, ['sem_dificuldades']);
    });

    test('selecionar outra dificuldade remove sem_dificuldades', () {
      final controller = SaudeController();
      controller.toggleDificuldadeSaude(DificuldadeSaude.semDificuldades);

      controller.toggleDificuldadeSaude(DificuldadeSaude.faltaProfissional);

      final codes = controller.buildSaudeData().dificuldadesSaude;
      expect(codes, contains('falta_profissional'));
      expect(codes, isNot(contains('sem_dificuldades')));
    });

    test('desmarcar sem_dificuldades esvazia a lista (permite deseleção)', () {
      final controller = SaudeController();
      controller.toggleDificuldadeSaude(DificuldadeSaude.semDificuldades);
      expect(controller.buildSaudeData().dificuldadesSaude, ['sem_dificuldades']);

      controller.toggleDificuldadeSaude(DificuldadeSaude.semDificuldades);
      expect(controller.buildSaudeData().dificuldadesSaude, isEmpty);
    });

    test('servicos_pre_natal é múltipla escolha de códigos', () {
      final controller = SaudeController();
      controller.toggleServicoPreNatal(ServicoPreNatal.consultaMedica);
      controller.toggleServicoPreNatal(ServicoPreNatal.grupoGestantes);

      expect(controller.buildSaudeData().servicosPreNatal, ['consulta_medica', 'grupo_gestantes']);
    });

    test('cadastrada_ubs é independente de acesso_ubs', () {
      final controller = SaudeController();

      controller.setCadastradaUBS(true);
      expect(controller.buildSaudeData().cadastradaUBS, isTrue);
      expect(controller.buildSaudeData().acessoUBS, isNull);

      controller.setAcessoUBS(AcessoUBS.aPe);
      expect(controller.buildSaudeData().cadastradaUBS, isTrue);
      expect(controller.buildSaudeData().acessoUBS, 'a_pe');

      controller.setAcessoUBS(AcessoUBS.transportePublico);
      expect(controller.buildSaudeData().cadastradaUBS, isTrue);

      controller.setAcessoUBS(null);
      expect(controller.buildSaudeData().cadastradaUBS, isTrue);
    });

    test('buildSaudeData serializa categorias por código (nunca label)', () {
      final controller = SaudeController();
      controller.setDistanciaUBS(DistanciaUBS.distante);
      controller.setAcessoUBS(AcessoUBS.transportePublico);
      controller.setAvaliacaoPreNatal(AvaliacaoPreNatal.bom);

      final data = controller.buildSaudeData();
      expect(data.distanciaUBS, 'distante');
      expect(data.acessoUBS, 'transporte_publico');
      expect(data.avaliacaoPreNatal, 'bom');
    });
  });
}
