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

    test('nenhum_dos_listados em serviços de pré-natal é mutuamente exclusiva', () {
      final controller = SaudeController();
      controller.toggleServicoPreNatal(ServicoPreNatal.consultaMedica);
      controller.toggleServicoPreNatal(ServicoPreNatal.grupoGestantes);

      controller.toggleServicoPreNatal(ServicoPreNatal.nenhumDosListados);

      expect(controller.buildSaudeData().servicosPreNatal, ['nenhum_dos_listados']);

      controller.toggleServicoPreNatal(ServicoPreNatal.consultaEnfermagem);
      final codes = controller.buildSaudeData().servicosPreNatal;
      expect(codes, contains('consulta_enfermagem'));
      expect(codes, isNot(contains('nenhum_dos_listados')));
      expect(codes, isNot(contains('Consulta médica regular')));
    });

    test('faltou_consulta, exames e vacinas começam null e preservam valores', () {
      final controller = SaudeController();
      expect(controller.faltouConsulta, isNull);
      expect(controller.examesPreNatalCompletos, isNull);
      expect(controller.vacinasEmDia, isNull);

      controller.setFaltouConsulta(true);
      controller.setExamesPreNatalCompletos(false);
      controller.setVacinasEmDia(true);

      final data = controller.buildSaudeData();
      expect(data.faltouConsulta, isTrue);
      expect(data.examesPreNatalCompletos, isFalse);
      expect(data.vacinasEmDia, isTrue);
    });

    test('isValid exige servicos_pre_natal, dificuldades_saude e cadastrada_ubs', () {
      final controller = SaudeController();
      controller.setDistanciaUBS(DistanciaUBS.distante);
      controller.setAcessoUBS(AcessoUBS.aPe);
      controller.setAvaliacaoPreNatal(AvaliacaoPreNatal.bom);

      expect(controller.isValid, isFalse); // listas vazias + cadastrada_ubs null

      controller.setCadastradaUBS(true);
      expect(controller.isValid, isFalse); // listas vazias

      controller.toggleServicoPreNatal(ServicoPreNatal.consultaMedica);
      expect(controller.isValid, isFalse); // dificuldades_saude ainda vazia

      controller.toggleDificuldadeSaude(DificuldadeSaude.semDificuldades);
      expect(controller.isValid, isTrue);
    });

    test('cadastrada_ubs: null invalida, "Não" (false) e "Sim" (true) validam', () {
      final controller = SaudeController();
      controller.setDistanciaUBS(DistanciaUBS.distante);
      controller.setAcessoUBS(AcessoUBS.aPe);
      controller.setAvaliacaoPreNatal(AvaliacaoPreNatal.bom);
      controller.toggleServicoPreNatal(ServicoPreNatal.consultaMedica);
      controller.toggleDificuldadeSaude(DificuldadeSaude.semDificuldades);

      expect(controller.cadastradaUBS, isNull);
      expect(controller.isValid, isFalse); // não respondida

      controller.setCadastradaUBS(false); // "Não" é resposta válida
      expect(controller.isValid, isTrue);
      expect(controller.buildSaudeData().cadastradaUBS, isFalse);

      controller.setCadastradaUBS(true); // "Sim" também
      expect(controller.isValid, isTrue);
      expect(controller.buildSaudeData().cadastradaUBS, isTrue);
    });
  });
}
