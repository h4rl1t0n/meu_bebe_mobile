import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/config/api_config.dart';
import 'package:meu_bebe/app/core/rest_client/risk_estimate_rest_client.dart';
import 'package:meu_bebe/app/modules/formulario/models/alimentacao/alimentacao_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/educacao/educacao_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/formulario_data.dart';
import 'package:meu_bebe/app/modules/formulario/models/habitacao/habitacao_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/saneamento/saneamento_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/saude/saude_model.dart';
import 'package:meu_bebe/app/modules/formulario/models/trabalho/trabalho_model.dart';
import 'package:meu_bebe/app/repositories/risk_estimate/risk_estimate_failure.dart';
import 'package:meu_bebe/app/repositories/risk_estimate/risk_estimate_repository_impl.dart';
import 'package:multiple_result/multiple_result.dart';

FormularioData _sample() => FormularioData(
  educacao: const EducacaoModel(
    estuda: true,
    escolaridade: 'medio_completo',
    situacaoEstudosGestacao: 'nao_interrompeu',
    dificuldadesEducacao: ['falta_dinheiro'],
    entendeOrientacoes: true,
    fezCursoQualificacaoProfissional: false,
  ),
  trabalho: const TrabalhoModel(
    empregado: true,
    tipoEmprego: 'clt',
    faixaRenda: 'ate_1_sm',
    permitePreNatal: true,
    ambienteSeguro: true,
    temPausas: false,
    beneficiosTrabalho: ['vale_transporte'],
  ),
  saneamento: SaneamentoModel.empty(),
  saude: SaudeModel.empty(),
  habitacao: HabitacaoModel.empty(),
  alimentacao: const AlimentacaoModel(
    refeicoesPorDia: 'tres',
    deixouDeComerFaltaDinheiro: false,
    alimentosConsumidos: ['frutas_verduras', 'feijao_leguminosas'],
    fonteAlimentos: ['supermercado_feira', 'horta_propria'],
    mudancaAlimentacaoGestacao: true,
    usaSuplementos: true,
    avaliacaoAlimentacao: 'boa',
  ),
);

Map<String, dynamic> _ok200() => {
  'result': {'target': 'descontinuou_pre_natal', 'probability': 0.321987654321},
  'model': {
    'name': 'random_forest',
    'schema_version': '1.13',
    'raw_feature_count': 34,
    'transformed_feature_count': 96,
  },
  'notice': 'Estimativa estatística experimental baseada em dados sintéticos.',
};

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> captured = [];
  final ResponseBody Function(RequestOptions options) handler;

  _RecordingAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

RiskEstimateRestClient _riskClientWith(_RecordingAdapter adapter) {
  final client = RiskEstimateRestClient();
  client.httpClientAdapter = adapter;
  // Base URL determinística para o teste; o client real usa ApiConfig.
  client.options.baseUrl = 'http://api.test';
  return client;
}

RiskEstimateRepositoryImpl _repo(
  _RecordingAdapter adapter, {
  String baseUrl = 'http://api.test',
}) {
  return RiskEstimateRepositoryImpl(
    client: _riskClientWith(adapter),
    config: ApiConfig(baseUrl),
  );
}

ResponseBody _json(int status, Map<String, dynamic> body) => ResponseBody(
  Stream.value(Uint8List.fromList(utf8.encode(jsonEncode(body)))),
  status,
  headers: const {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  group('RiskEstimateRepositoryImpl.estimate', () {
    test('200 → Success, probability preservada sem arredondamento', () async {
      final adapter = _RecordingAdapter((_) => _json(200, _ok200()));
      final repo = _repo(adapter);

      final result = await repo.estimate(_sample());

      switch (result) {
        case Success(success: final model):
          expect(model.result.target, 'descontinuou_pre_natal');
          expect(model.result.probability, 0.321987654321);
          expect(model.model.name, 'random_forest');
          expect(model.model.schemaVersion, '1.13');
          expect(model.model.rawFeatureCount, 34);
          expect(model.model.transformedFeatureCount, 96);
          expect(model.notice, isNotEmpty);
        case Error(error: final failure):
          fail('esperado sucesso, veio $failure');
      }
    });

    test(
      'enviou POST para /api/v1/risk-estimate com corpo = FormularioData.toMap()',
      () async {
        final data = _sample();
        final adapter = _RecordingAdapter((_) => _json(200, _ok200()));
        final repo = _repo(adapter);

        await repo.estimate(data);

        expect(adapter.captured, hasLength(1));
        final request = adapter.captured.single;
        expect(request.method, 'POST');
        expect(request.path, RiskEstimateRepositoryImpl.endpointPath);

        final sent = request.data as Map<String, dynamic>;
        // Corpo preserva exatamente a representação canônica aninhada e versionada.
        expect(sent, data.toMap());
        expect(sent['schema_version'], '1.13');
        // 6 dimensões + schema_version = 7 chaves (não achatado).
        expect(sent.keys, hasLength(7));
        for (final dim in [
          'educacao',
          'trabalho',
          'saneamento',
          'saude',
          'habitacao',
          'alimentacao',
        ]) {
          expect(
            sent[dim],
            isA<Map<String, dynamic>>(),
            reason: 'dimensão $dim',
          );
        }
        // Não é flat: chaves de campo não aparecem no topo nem como `dimensao.campo`.
        expect(sent.containsKey('escolaridade'), isFalse);
        expect(sent.containsKey('educacao.escolaridade'), isFalse);

        expect(request.headers[Headers.acceptHeader], Headers.jsonContentType);
        expect(
          (request.headers[Headers.contentTypeHeader] as String),
          contains('application/json'),
        );
      },
    );

    test('não repete a requisição (sem retry automático)', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(503, {
          'error': {'code': 'MODEL_NOT_READY'},
        }),
      );
      final repo = _repo(adapter);

      await repo.estimate(_sample());

      expect(adapter.captured, hasLength(1));
    });

    test('422 → ValidationFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(422, {
          'code': 'VALIDATION_ERROR',
          'message': 'Requisição inválida',
          'details': [
            {
              'loc': ['body', 'educacao', 'escolaridade'],
              'msg': 'inválido',
              'type': 'enum',
            },
          ],
        }),
      );
      final repo = _repo(adapter);

      final result = await repo.estimate(_sample());

      switch (result) {
        case Error(error: final failure):
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).details, hasLength(1));
        case Success():
          fail('esperado ValidationFailure');
      }
    });

    test('503 → ModelNotReadyFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(503, {
          'error': {'code': 'MODEL_NOT_READY'},
        }),
      );
      final repo = _repo(adapter);

      final result = await repo.estimate(_sample());

      switch (result) {
        case Error(error: final failure):
          expect(failure, isA<ModelNotReadyFailure>());
        case Success():
          fail('esperado ModelNotReadyFailure');
      }
    });

    test('500 → InferenceFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(500, {
          'error': {'code': 'INFERENCE_ERROR'},
        }),
      );
      final repo = _repo(adapter);

      final result = await repo.estimate(_sample());

      switch (result) {
        case Error(error: final failure):
          expect(failure, isA<InferenceFailure>());
        case Success():
          fail('esperado InferenceFailure');
      }
    });

    test('200 malformado → InvalidResponseFailure (sem TypeError)', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(200, {'inesperado': true}),
      );
      final repo = _repo(adapter);

      final result = await repo.estimate(_sample());

      switch (result) {
        case Error(error: final failure):
          expect(failure, isA<InvalidResponseFailure>());
          expect(failure.message, 'Resposta inválida do serviço.');
        case Success():
          fail('esperado InvalidResponseFailure');
      }
    });

    test(
      'baseUrl vazio → ConfigurationFailure, sem efetuar requisição',
      () async {
        final adapter = _RecordingAdapter((_) => _json(200, _ok200()));
        final repo = RiskEstimateRepositoryImpl(
          client: _riskClientWith(adapter),
          config: const ApiConfig(''),
        );

        final result = await repo.estimate(_sample());

        switch (result) {
          case Error(error: final failure):
            expect(failure, isA<ConfigurationFailure>());
            expect(failure.message, 'URL da API não configurada.');
          case Success():
            fail('esperado ConfigurationFailure');
        }
        expect(adapter.captured, isEmpty);
      },
    );
  });
}
