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
import 'package:meu_bebe/app/repositories/risk_estimate/risk_estimate_failure.dart';
import 'package:meu_bebe/app/repositories/risk_estimate/risk_estimate_repository.dart';
import 'package:multiple_result/multiple_result.dart';

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

FormularioController _buildController(RiskEstimateRepository repository) {
  return FormularioController(
    riskEstimateRepository: repository,
    educacaoCtrl: EducacaoController(),
    trabalhoCtrl: TrabalhoController(),
    saneamentoCtrl: SaneamentoController(),
    saudeCtrl: SaudeController(),
    habitacaoCtrl: HabitacaoController(),
    alimentacaoCtrl: AlimentacaoController(),
  );
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
}
