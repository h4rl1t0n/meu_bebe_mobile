import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/ui/theme/app_theme.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/alimentacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/educacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/habitacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/saneamento_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/saude_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/trabalho_options.dart';
import 'package:meu_bebe/app/modules/formulario/controllers/formulario_controller.dart';
import 'package:meu_bebe/app/modules/formulario/formulario_page.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/alimentacao/alimentacao_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/educacao/educacao_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/habitacao/habitacao_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/saneamento/saneamento_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/saude/saude_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/trabalho/trabalho_controller.dart';
import 'package:meu_bebe/app/repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:meu_bebe/app/repositories/risk_estimate/risk_estimate_repository.dart';

/// Testes de PÁGINA do Formulário DSS (FASE 9J-PRE-FIX1 — correção da barra
/// inferior).
///
/// A navegação inferior preserva o comportamento já existente: Etapa 1 só
/// "Próximo"; Etapas 2–5 "Voltar" + "Próximo"; Etapa 6 "Voltar" + "Enviar
/// avaliação". A seta superior do AppBar é navegação de ROTA (não volta etapa).

class _NoopRiskEstimateRepository implements RiskEstimateRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAvaliacaoDssRepository implements AvaliacaoDssRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopPerfilRepository implements PerfilRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FormularioScopeModule extends Module {
  _FormularioScopeModule(this.controller);

  final FormularioController controller;

  @override
  void binds(Injector i) {
    i.addInstance<FormularioController>(controller);
    i.addInstance<EducacaoController>(controller.educacaoCtrl);
    i.addInstance<TrabalhoController>(controller.trabalhoCtrl);
    i.addInstance<SaneamentoController>(controller.saneamentoCtrl);
    i.addInstance<SaudeController>(controller.saudeCtrl);
    i.addInstance<HabitacaoController>(controller.habitacaoCtrl);
    i.addInstance<AlimentacaoController>(controller.alimentacaoCtrl);
  }

  @override
  void routes(RouteManager r) {
    r.child(Modular.initialRoute, child: (context) => const FormularioPage());
  }
}

Widget _mount(FormularioController controller) {
  return ModularApp(
    module: _FormularioScopeModule(controller),
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: Modular.routerConfig,
    ),
  );
}

FormularioController _makeController() {
  return FormularioController(
    riskEstimateRepository: _NoopRiskEstimateRepository(),
    avaliacaoDssRepository: _NoopAvaliacaoDssRepository(),
    perfilRepository: _NoopPerfilRepository(),
    educacaoCtrl: EducacaoController(),
    trabalhoCtrl: TrabalhoController(),
    saneamentoCtrl: SaneamentoController(),
    saudeCtrl: SaudeController(),
    habitacaoCtrl: HabitacaoController(),
    alimentacaoCtrl: AlimentacaoController(),
  );
}

/// Preenche as seis dimensões com respostas válidas (mesma montagem do teste
/// do controller), de modo que `validateAll()` retorne `true`.
void _fillForm(FormularioController controller) {
  final educacao = controller.educacaoCtrl;
  educacao.setEstuda(true);
  educacao.setEscolaridade(Escolaridade.medioCompleto);
  educacao.setSituacaoEstudosGestacao(SituacaoEstudosGestacao.naoEstudava);
  educacao.setEntendeOrientacoes(true);
  educacao.setFezCursoQualificacaoProfissional(false);
  educacao.toggleDificuldade(DificuldadeEducacao.semDificuldades);

  final trabalho = controller.trabalhoCtrl;
  trabalho.setEmpregado(true);
  trabalho.setTipoEmprego(TipoEmprego.clt);
  trabalho.setFaixaRenda(FaixaRenda.ate1Sm);
  trabalho.setRecebeBeneficioSocial(false);
  trabalho.toggleBeneficio(BeneficioTrabalho.valeTransporte);

  final saneamento = controller.saneamentoCtrl;
  saneamento.setFonteAgua(FonteAgua.redePublica);
  saneamento.setInterrupcoesAgua(false);
  saneamento.setEsgotamentoSanitario(EsgotamentoSanitario.redeColetora);
  saneamento.setFrequenciaColetaLixo(FrequenciaColetaLixo.regular);
  saneamento.setPreocupacaoAgua(false);
  saneamento.toggleCuidadoVetor(CuidadoVetor.semCuidados);

  final saude = controller.saudeCtrl;
  saude.setDistanciaUBS(DistanciaUBS.muitoProxima);
  saude.setAcessoUBS(AcessoUBS.aPe);
  saude.setCadastradaUBS(true);
  saude.setAvaliacaoPreNatal(AvaliacaoPreNatal.bom);
  saude.toggleServicoPreNatal(ServicoPreNatal.consultaMedica);
  saude.toggleDificuldadeSaude(DificuldadeSaude.semDificuldades);

  final habitacao = controller.habitacaoCtrl;
  habitacao.setTipoMoradia(TipoMoradia.casa);
  habitacao.setMaterialMoradia(MaterialMoradia.alvenaria);
  habitacao.setNumeroPessoas(3);
  habitacao.setNumeroComodos(5);
  habitacao.setNumeroDormitorios(2);
  habitacao.setSegurancaResidencia(SegurancaResidencia.segura);
  habitacao.setFacilAcessoSaude(true);
  habitacao.toggleItemResidencia(ItemResidencia.aguaEncanada);
  habitacao.toggleMelhoriaMoradia(MelhoriaMoradia.semMelhorias);

  final alimentacao = controller.alimentacaoCtrl;
  alimentacao.setRefeicoesPorDia(RefeicoesPorDia.tres);
  alimentacao.setDeixouComerFaltaDinheiro(false);
  alimentacao.setMudancaAlimentacaoGestacao(false);
  alimentacao.setUsaSuplementos(true);
  alimentacao.setAvaliacaoAlimentacao(AvaliacaoAlimentacao.boa);
  alimentacao.toggleAlimento(AlimentoConsumido.frutasVerduras);
  alimentacao.toggleFonteAlimento(FonteAlimentos.supermercadoFeira);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FormularioPage — barra inferior (correção FASE 9J-PRE-FIX1)', () {
    testWidgets('Etapa 1: "Voltar" inferior ausente e "Próximo" presente',
        (tester) async {
      final controller = _makeController();
      await tester.pumpWidget(_mount(controller));
      await tester.pumpAndSettle();

      expect(find.text('Voltar'), findsNothing);
      expect(find.text('Próximo'), findsOneWidget);
    });

    testWidgets('Etapa 2: "Voltar" e "Próximo" presentes', (tester) async {
      final controller = _makeController();
      await tester.pumpWidget(_mount(controller));
      await tester.pumpAndSettle();

      controller.goToStep(1);
      await tester.pumpAndSettle();

      expect(find.text('2 de 6'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);
      expect(find.text('Próximo'), findsOneWidget);
    });

    testWidgets('tap em "Voltar" na etapa 2 retorna à etapa 1', (tester) async {
      final controller = _makeController();
      await tester.pumpWidget(_mount(controller));
      await tester.pumpAndSettle();

      controller.goToStep(1);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      expect(find.text('1 de 6'), findsOneWidget);
      expect(controller.currentStep, 0);
    });

    testWidgets('Etapa 5: "Voltar" e "Próximo" presentes', (tester) async {
      final controller = _makeController();
      await tester.pumpWidget(_mount(controller));
      await tester.pumpAndSettle();

      controller.goToStep(4);
      await tester.pumpAndSettle();

      expect(find.text('5 de 6'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);
      expect(find.text('Próximo'), findsOneWidget);
      expect(find.text('Enviar avaliação'), findsNothing);
    });

    testWidgets('Etapa 6: "Voltar" e "Enviar avaliação" presentes',
        (tester) async {
      final controller = _makeController();
      await tester.pumpWidget(_mount(controller));
      await tester.pumpAndSettle();

      controller.goToStep(5);
      await tester.pumpAndSettle();

      expect(find.text('6 de 6'), findsOneWidget);
      expect(find.text('Voltar'), findsOneWidget);
      expect(find.text('Enviar avaliação'), findsOneWidget);
      expect(find.text('Próximo'), findsNothing);
    });

    testWidgets('tap em "Voltar" na etapa 6 retorna à etapa 5', (tester) async {
      final controller = _makeController();
      await tester.pumpWidget(_mount(controller));
      await tester.pumpAndSettle();

      controller.goToStep(5);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      expect(find.text('5 de 6'), findsOneWidget);
      expect(controller.currentStep, 4);
    });

    testWidgets('"Próximo" não avança quando a etapa é inválida e marca erros',
        (tester) async {
      final controller = _makeController();
      await tester.pumpWidget(_mount(controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('1 de 6'), findsOneWidget); // permanece na etapa 1
      expect(controller.currentStep, 0);
      expect(controller.educacaoCtrl.showErrors, isTrue);
      expect(find.text('Campo obrigatório'), findsWidgets);
    });

    testWidgets('"Próximo" avança quando a etapa é válida', (tester) async {
      final controller = _makeController();
      await tester.pumpWidget(_mount(controller));
      await tester.pumpAndSettle();

      _fillForm(controller);
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('2 de 6'), findsOneWidget);
      expect(controller.currentStep, 1);
    });

    testWidgets('"Enviar avaliação" não envia formulário inválido',
        (tester) async {
      final controller = _makeController();
      await tester.pumpWidget(_mount(controller));
      await tester.pumpAndSettle();

      controller.goToStep(5);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar avaliação'));
      await tester.pumpAndSettle();

      // Não abre o resumo: salta para a primeira etapa inválida e marca erros.
      expect(find.text('Resumo do Formulário'), findsNothing);
      expect(find.text('1 de 6'), findsOneWidget);
      expect(controller.currentStep, 0);
      expect(find.text('Campo obrigatório'), findsWidgets);
    });

    testWidgets('"Enviar avaliação" abre o resumo quando tudo é válido',
        (tester) async {
      final controller = _makeController();
      await tester.pumpWidget(_mount(controller));
      await tester.pumpAndSettle();

      _fillForm(controller);
      controller.goToStep(5);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar avaliação'));
      await tester.pumpAndSettle();

      expect(find.text('Resumo do Formulário'), findsOneWidget);
    });
  });
}
