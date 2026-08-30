import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/enum/page_status.dart';
import 'package:meu_bebe/app/modules/formulario/controllers/formulario_controller.dart';
import 'package:meu_bebe/app/modules/formulario/models/formulario_data.dart';
import 'package:meu_bebe/app/modules/formulario/models/risk_estimate/risk_estimate_response_model.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/alimentacao/alimentacao_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/educacao/educacao_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/habitacao/habitacao_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/saneamento/saneamento_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/saude/saude_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/trabalho/trabalho_controller.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart'
    show BackendFailure, UnexpectedFailure;
import 'package:meu_bebe/app/model/auth/auth_models.dart';
import 'package:meu_bebe/app/model/avaliacao_dss/avaliacao_dss_model.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:meu_bebe/app/repositories/risk_estimate/risk_estimate_failure.dart';
import 'package:meu_bebe/app/repositories/risk_estimate/risk_estimate_repository.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/alimentacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/educacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/habitacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/saneamento_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/saude_options.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/trabalho_options.dart';

const _successResponse = RiskEstimateResponseModel(
  result: RiskEstimateResultModel(
    target: 'descontinuou_pre_natal',
    probability: 0.321987654321,
  ),
  model: RiskEstimateModelMetadata(
    name: 'random_forest',
    schemaVersion: '1.13',
    rawFeatureCount: 34,
    transformedFeatureCount: 96,
  ),
  notice: 'Estimativa estatística experimental baseada em dados sintéticos.',
);

Result<RiskEstimateResponseModel, RiskEstimateFailure> _success() =>
    const Success(_successResponse);

Result<RiskEstimateResponseModel, RiskEstimateFailure> _error(
  RiskEstimateFailure failure,
) => Error(failure);

class _FakeRiskEstimateRepository implements RiskEstimateRepository {
  final Future<Result<RiskEstimateResponseModel, RiskEstimateFailure>> Function(
    FormularioData data,
  )
  handler;

  int callCount = 0;
  FormularioData? captured;

  _FakeRiskEstimateRepository(this.handler);

  @override
  Future<Result<RiskEstimateResponseModel, RiskEstimateFailure>> estimate(
    FormularioData data,
  ) {
    callCount++;
    captured = data;
    return handler(data);
  }
}

const _avaliacao = AvaliacaoDssModel(
  id: 'avaliacao-1',
  schemaVersion: '1.13',
  respostas: <String, dynamic>{},
  createdAt: '2026-08-29T00:00:00Z',
);

class _FakeAvaliacaoDssRepository implements AvaliacaoDssRepository {
  final Future<Result<AvaliacaoDssModel, BackendFailure>> Function(
    String gestacaoId,
    FormularioData data,
  )
  handler;

  int callCount = 0;
  String? capturedGestacaoId;
  FormularioData? capturedData;

  _FakeAvaliacaoDssRepository(this.handler);

  @override
  Future<Result<AvaliacaoDssModel, BackendFailure>> registrar(
    String gestacaoId,
    FormularioData data,
  ) {
    callCount++;
    capturedGestacaoId = gestacaoId;
    capturedData = data;
    return handler(gestacaoId, data);
  }

  @override
  Future<Result<List<AvaliacaoDssModel>, BackendFailure>> list(
    String gestacaoId,
  ) async => const Success(<AvaliacaoDssModel>[]);
}

class _FakePerfilRepository implements PerfilRepository {
  final Future<Result<GestacaoModel?, BackendFailure>> Function()
      getGestacaoAtualHandler;

  int getGestacaoAtualCallCount = 0;

  _FakePerfilRepository(this.getGestacaoAtualHandler);

  @override
  Future<Result<GestacaoModel?, BackendFailure>> getGestacaoAtual() {
    getGestacaoAtualCallCount++;
    return getGestacaoAtualHandler();
  }

  @override
  Future<Result<UserResponseModel?, BackendFailure>> getUser() =>
      throw UnimplementedError();

  @override
  Future<Result<GestanteModel?, BackendFailure>> getGestante() =>
      throw UnimplementedError();

  @override
  Future<Result<GestanteModel, BackendFailure>> createGestante(
    GestanteModel gestante,
  ) => throw UnimplementedError();

  @override
  Future<Result<GestanteModel, BackendFailure>> updateGestante(
    GestanteModel gestante,
  ) => throw UnimplementedError();
}

/// Preenche as seis dimensões com respostas válidas, de modo que
/// `validateAll()` retorne `true` e `enviarFormulario()` prossiga (FASE
/// 9G-FIX2: o guard de inferência bloqueia formulários incompletos).
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

FormularioController _buildController(
  RiskEstimateRepository repository, {
  PerfilRepository? perfilRepository,
  AvaliacaoDssRepository? avaliacaoDssRepository,
  bool fillForm = true,
}) {
  final controller = FormularioController(
    riskEstimateRepository: repository,
    avaliacaoDssRepository:
        avaliacaoDssRepository ??
        _FakeAvaliacaoDssRepository(
          (_, _) async => const Success(_avaliacao),
        ),
    perfilRepository:
        perfilRepository ??
        _FakePerfilRepository(() async => const Success(null)),
    educacaoCtrl: EducacaoController(),
    trabalhoCtrl: TrabalhoController(),
    saneamentoCtrl: SaneamentoController(),
    saudeCtrl: SaudeController(),
    habitacaoCtrl: HabitacaoController(),
    alimentacaoCtrl: AlimentacaoController(),
  );
  if (fillForm) {
    _fillForm(controller);
  }
  return controller;
}

void main() {
  group('FormularioController.enviarFormulario', () {
    test('estado inicial: idle, sem resultado, sem erro, sem loading', () {
      final controller = _buildController(
        _FakeRiskEstimateRepository((_) async => _success()),
      );

      expect(controller.status, PageStatus.initial);
      expect(controller.loading, isFalse);
      expect(controller.riskEstimate, isNull);
      expect(controller.error, isNull);
    });

    test(
      'durante a submissão status == loading e encerra ao concluir',
      () async {
        final completer =
            Completer<Result<RiskEstimateResponseModel, RiskEstimateFailure>>();
        final repo = _FakeRiskEstimateRepository((_) => completer.future);
        final controller = _buildController(repo);

        final future = controller.enviarFormulario();

        expect(controller.status, PageStatus.loading);
        expect(controller.loading, isTrue);

        completer.complete(_success());
        await future;

        expect(controller.loading, isFalse);
        expect(controller.status, isNot(PageStatus.loading));
      },
    );

    test(
      'sucesso: uma chamada, status success, resposta completa preservada, erro limpo',
      () async {
        final repo = _FakeRiskEstimateRepository((_) async => _success());
        final controller = _buildController(repo);

        await controller.enviarFormulario();

        expect(repo.callCount, 1);
        expect(controller.status, PageStatus.success);
        expect(controller.error, isNull);

        final estimate = controller.riskEstimate;
        expect(estimate, isNotNull);
        expect(estimate!.result.target, 'descontinuou_pre_natal');
        // probability preservada sem arredondamento.
        expect(estimate.result.probability, 0.321987654321);
        expect(estimate.model.name, 'random_forest');
        expect(estimate.model.schemaVersion, '1.13');
        expect(estimate.model.rawFeatureCount, 34);
        expect(estimate.model.transformedFeatureCount, 96);
        expect(estimate.notice, isNotEmpty);
      },
    );

    test(
      'falha: status error, mensagem amigável, sem resultado, loading encerrado',
      () async {
        final repo = _FakeRiskEstimateRepository(
          (_) async => _error(const ConnectionFailure()),
        );
        final controller = _buildController(repo);

        await controller.enviarFormulario();

        expect(controller.status, PageStatus.error);
        expect(controller.error, 'Não foi possível conectar ao serviço.');
        expect(controller.riskEstimate, isNull);
        expect(controller.loading, isFalse);
      },
    );

    test(
      'duplo envio: segunda chamada é ignorada (uma única requisição)',
      () async {
        final completer =
            Completer<Result<RiskEstimateResponseModel, RiskEstimateFailure>>();
        final repo = _FakeRiskEstimateRepository((_) => completer.future);
        final controller = _buildController(repo);

        final first = controller.enviarFormulario();
        final second = controller.enviarFormulario();

        completer.complete(_success());
        await Future.wait([first, second]);

        expect(repo.callCount, 1);
        expect(controller.status, PageStatus.success);
      },
    );

    test('nova tentativa após erro: limpa o erro e chega ao sucesso', () async {
      var fail = true;
      final repo = _FakeRiskEstimateRepository((_) async {
        if (fail) {
          fail = false;
          return _error(const ModelNotReadyFailure());
        }
        return _success();
      });
      final controller = _buildController(repo);

      await controller.enviarFormulario();
      expect(controller.status, PageStatus.error);
      expect(controller.error, 'Modelo de inferência indisponível.');

      await controller.enviarFormulario();

      expect(repo.callCount, 2);
      expect(controller.status, PageStatus.success);
      expect(controller.error, isNull);
      expect(controller.riskEstimate, isNotNull);
    });

    test('sem retry automático: uma falha permanece com uma chamada', () async {
      final repo = _FakeRiskEstimateRepository(
        (_) async => _error(const ServiceUnavailableFailure()),
      );
      final controller = _buildController(repo);

      await controller.enviarFormulario();

      expect(repo.callCount, 1);
      expect(controller.status, PageStatus.error);
    });

    test(
      'entrega FormularioData consolidado (não toFlatMap) ao repositório',
      () async {
        final repo = _FakeRiskEstimateRepository((_) async => _success());
        final controller = _buildController(repo);

        await controller.enviarFormulario();

        expect(repo.callCount, 1);
        final captured = repo.captured;
        expect(captured, isNotNull);
        expect(captured, isA<FormularioData>());
      },
    );
  });

  group('FormularioController — persistência operacional (FASE 9F)', () {
    test('persistência OK: registrar com gestacao.id + estimativa success',
        () async {
      final avalRepo = _FakeAvaliacaoDssRepository(
        (_, _) async => const Success(_avaliacao),
      );
      final controller = _buildController(
        _FakeRiskEstimateRepository((_) async => _success()),
        perfilRepository: _FakePerfilRepository(
          () async => const Success(GestacaoModel(id: 'gestacao-1')),
        ),
        avaliacaoDssRepository: avalRepo,
      );

      await controller.enviarFormulario();

      expect(controller.status, PageStatus.success);
      expect(controller.persisted, isTrue);
      expect(controller.noActiveGestacao, isFalse);
      expect(controller.persistenceError, isNull);
      expect(avalRepo.callCount, 1);
      expect(avalRepo.capturedGestacaoId, 'gestacao-1');
      expect(avalRepo.capturedData, isA<FormularioData>());
    });

    test('sem gestação ativa: NÃO faz POST e sinaliza noActiveGestacao',
        () async {
      final avalRepo = _FakeAvaliacaoDssRepository(
        (_, _) async => const Success(_avaliacao),
      );
      final controller = _buildController(
        _FakeRiskEstimateRepository((_) async => _success()),
        perfilRepository: _FakePerfilRepository(
          () async => const Success(null),
        ),
        avaliacaoDssRepository: avalRepo,
      );

      await controller.enviarFormulario();

      expect(controller.status, PageStatus.success);
      expect(controller.noActiveGestacao, isTrue);
      expect(controller.persisted, isFalse);
      expect(controller.persistenceError, isNull);
      expect(avalRepo.callCount, 0);
    });

    test('falha na persistência: mensagem amigável, estimativa não afetada',
        () async {
      final controller = _buildController(
        _FakeRiskEstimateRepository((_) async => _success()),
        perfilRepository: _FakePerfilRepository(
          () async => const Success(GestacaoModel(id: 'gestacao-1')),
        ),
        avaliacaoDssRepository: _FakeAvaliacaoDssRepository(
          (_, _) async => const Error(UnexpectedFailure()),
        ),
      );

      await controller.enviarFormulario();

      expect(controller.status, PageStatus.success);
      expect(controller.persisted, isFalse);
      expect(
        controller.persistenceError,
        'Não foi possível concluir a operação.',
      );
      expect(controller.error, isNull);
    });

    test('falha na estimativa: persistência concluída de forma independente',
        () async {
      final avalRepo = _FakeAvaliacaoDssRepository(
        (_, _) async => const Success(_avaliacao),
      );
      final controller = _buildController(
        _FakeRiskEstimateRepository(
          (_) async => _error(const ConnectionFailure()),
        ),
        perfilRepository: _FakePerfilRepository(
          () async => const Success(GestacaoModel(id: 'gestacao-1')),
        ),
        avaliacaoDssRepository: avalRepo,
      );

      await controller.enviarFormulario();

      expect(controller.status, PageStatus.error);
      expect(controller.error, 'Não foi possível conectar ao serviço.');
      expect(controller.persisted, isTrue);
      expect(avalRepo.callCount, 1);
    });

    test('retry após sucesso: NÃO duplica o POST append-only', () async {
      final avalRepo = _FakeAvaliacaoDssRepository(
        (_, _) async => const Success(_avaliacao),
      );
      final estimateRepo = _FakeRiskEstimateRepository((_) async => _success());
      final controller = _buildController(
        estimateRepo,
        perfilRepository: _FakePerfilRepository(
          () async => const Success(GestacaoModel(id: 'gestacao-1')),
        ),
        avaliacaoDssRepository: avalRepo,
      );

      await controller.enviarFormulario();
      await controller.enviarFormulario();

      expect(avalRepo.callCount, 1);
      expect(estimateRepo.callCount, 2);
    });

    test('sem gestação: respostas preservadas e NÃO auto-cria gestação',
        () async {
      final estimateRepo = _FakeRiskEstimateRepository((_) async => _success());
      final controller = _buildController(
        estimateRepo,
        perfilRepository: _FakePerfilRepository(
          () async => const Success(null),
        ),
        avaliacaoDssRepository: _FakeAvaliacaoDssRepository(
          (_, _) async => const Success(_avaliacao),
        ),
      );

      await controller.enviarFormulario();

      // Respostas NÃO são descartadas: o FormularioData consolidado segue
      // entregue à estimativa. Nenhuma tentativa de criar gestação (o fake de
      // `createGestante` lançaria UnimplementedError se fosse chamado).
      expect(estimateRepo.captured, isA<FormularioData>());
      expect(controller.consolidatedData, isA<FormularioData>());
      expect(controller.noActiveGestacao, isTrue);
    });
  });

  group('FormularioController — validação DSS (FASE 9G-FIX2)', () {
    test(
      'formulário inválido: enviarFormulario NÃO dispara HTTP e marca erros',
      () async {
        final repo = _FakeRiskEstimateRepository((_) async => _success());
        final avalRepo = _FakeAvaliacaoDssRepository(
          (_, _) async => const Success(_avaliacao),
        );
        final controller = _buildController(
          repo,
          fillForm: false,
          perfilRepository: _FakePerfilRepository(
            () async => const Success(GestacaoModel(id: 'gestacao-1')),
          ),
          avaliacaoDssRepository: avalRepo,
        );

        expect(controller.validateAll(), isFalse);

        await controller.enviarFormulario();

        // ZERO HTTP: nenhuma estimativa e nenhuma persistência.
        expect(repo.callCount, 0);
        expect(avalRepo.callCount, 0);
        expect(controller.status, PageStatus.initial);
        // Erros obrigatórios marcados em todas as dimensões.
        expect(controller.saudeCtrl.showErrors, isTrue);
        expect(controller.educacaoCtrl.showErrors, isTrue);
      },
    );

    test('validateAll reflete a validade das seis dimensões', () {
      final controller = _buildController(
        _FakeRiskEstimateRepository((_) async => _success()),
      );
      expect(controller.validateAll(), isTrue);

      controller.saudeCtrl.setCadastradaUBS(null); // "não respondida"
      expect(controller.validateAll(), isFalse);
    });

    test('firstInvalidStep aponta a primeira dimensão inválida na ordem', () {
      final controller = _buildController(
        _FakeRiskEstimateRepository((_) async => _success()),
      );
      expect(controller.firstInvalidStep, isNull);

      controller.trabalhoCtrl.setRecebeBeneficioSocial(null); // passo 1
      controller.saudeCtrl.setCadastradaUBS(null); // passo 3
      expect(controller.firstInvalidStep, 1); // Trabalho antes de Saúde
    });

    test(
      'markStepErrors / clearStepErrors / markAllErrors controlam showErrors',
      () {
        final controller = _buildController(
          _FakeRiskEstimateRepository((_) async => _success()),
        );

        expect(controller.educacaoCtrl.showErrors, isFalse);

        controller.markStepErrors(0);
        expect(controller.educacaoCtrl.showErrors, isTrue);

        controller.clearStepErrors(0);
        expect(controller.educacaoCtrl.showErrors, isFalse);

        controller.markAllErrors();
        expect(controller.educacaoCtrl.showErrors, isTrue);
        expect(controller.trabalhoCtrl.showErrors, isTrue);
        expect(controller.saneamentoCtrl.showErrors, isTrue);
        expect(controller.saudeCtrl.showErrors, isTrue);
        expect(controller.habitacaoCtrl.showErrors, isTrue);
        expect(controller.alimentacaoCtrl.showErrors, isTrue);
      },
    );
  });
}
