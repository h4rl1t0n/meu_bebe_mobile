import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';
import 'package:meu_bebe/app/repositories/plano_parto/plano_parto_repository_impl.dart';
import 'package:multiple_result/multiple_result.dart';

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

ResponseBody _json(int status, Object body) => ResponseBody(
  Stream.value(Uint8List.fromList(utf8.encode(jsonEncode(body)))),
  status,
  headers: const {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

DioForNative _clientWith(_RecordingAdapter adapter) {
  final client = DioForNative(BaseOptions(baseUrl: 'http://api.test'));
  client.httpClientAdapter = adapter;
  return client;
}

Map<String, dynamic> _planoBody() => {
  'id': 'pp-1',
  'acompanhante': 'sim',
  'raspar_pelos_intimos': 'nao',
  'lavagem_intestinal': 'nao_sei',
  'ambiente_pouca_luz': 'sim',
  'ouvir_musica': 'nao',
  'beber_liquidos': 'sim',
  'registrar_fotos_videos': 'nao_sei',
  'via_parto': 'vaginal',
  'anestesia': 'sim',
  'corte_vaginal': 'nao',
  'posicao_preferida': 'sentada',
  'outra_posicao': null,
  'quem_corta_cordao': 'acompanhante',
  'coleta_celulas_tronco': true,
  'contato_pele_a_pele': 'sim',
  'amamentar_primeira_hora': 'sim',
  'restricoes_amamentacao': false,
  'primeiro_banho': 'profissional',
  'quer_alivio_dor': 'sim',
  'massagem': true,
  'exercicios_bola': true,
  'exercicios_respiracao': false,
  'banho_chuveiro': true,
  'banho_banheira': false,
  'acupuntura': false,
  'acupressao': true,
  'outro_metodo': false,
  'observacoes': 'Prefiro luz baixa',
};

const _gestacaoId = 'ges-1';
const _basePath = '/api/v1/gestacoes/ges-1/plano-de-parto';

void main() {
  group('PlanoPartoRepositoryImpl.getPlanoParto', () {
    test('200 → Success com plano parseado (28 campos)', () async {
      final adapter = _RecordingAdapter((_) => _json(200, _planoBody()));
      final repo = PlanoPartoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.getPlanoParto(_gestacaoId);

      switch (result) {
        case Success(success: final plano):
          expect(plano, isNotNull);
          expect(plano!.id, 'pp-1');
          expect(plano.acompanhante, 'sim');
          expect(plano.viaParto, 'vaginal');
          expect(plano.massagem, isTrue);
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'GET');
      expect(adapter.captured.single.path, _basePath);
    });

    test('404 → Success(null) — primeiro salvamento', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(404, {'code': 'PLANO_PARTO_NOT_FOUND'}),
      );
      final repo = PlanoPartoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.getPlanoParto(_gestacaoId);

      switch (result) {
        case Success(success: final plano):
          expect(plano, isNull);
        case Error(error: final f):
          fail('esperado Success(null), veio $f');
      }
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = PlanoPartoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.getPlanoParto(_gestacaoId);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<SessionExpiredFailure>());
        case Success():
          fail('esperado SessionExpiredFailure');
      }
    });

    test('offline → NetworkFailure', () async {
      final adapter = _RecordingAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      final repo = PlanoPartoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.getPlanoParto(_gestacaoId);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<NetworkFailure>());
        case Success():
          fail('esperado NetworkFailure');
      }
    });
  });

  group('PlanoPartoRepositoryImpl.upsertPlanoParto', () {
    test('PUT 200 → Success + payload completo sem id/gestacao_id/timestamps',
        () async {
      final adapter = _RecordingAdapter((_) => _json(200, _planoBody()));
      final repo = PlanoPartoRepositoryImpl(client: _clientWith(adapter));
      final plano = PlanoPartoModel.tryParse(_planoBody())!;

      final result = await repo.upsertPlanoParto(_gestacaoId, plano);

      switch (result) {
        case Success(success: final saved):
          expect(saved.id, 'pp-1');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'PUT');
      expect(adapter.captured.single.path, _basePath);
      final sent = adapter.captured.single.data as Map<String, dynamic>;
      expect(sent.length, 28);
      expect(sent.containsKey('id'), isFalse);
      expect(sent.containsKey('gestacao_id'), isFalse);
      expect(sent.containsKey('created_at'), isFalse);
      expect(sent['acompanhante'], 'sim');
      expect(sent['via_parto'], 'vaginal');
      expect(sent['coleta_celulas_tronco'], true);
      expect(sent['observacoes'], 'Prefiro luz baixa');
    });

    test('422 → ValidationFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(422, {'code': 'VALIDATION_ERROR'}),
      );
      final repo = PlanoPartoRepositoryImpl(client: _clientWith(adapter));
      final plano = PlanoPartoModel.tryParse(_planoBody())!;

      final result = await repo.upsertPlanoParto(_gestacaoId, plano);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<ValidationFailure>());
        case Success():
          fail('esperado ValidationFailure');
      }
    });

    test('401 → SessionExpiredFailure (via mapper)', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = PlanoPartoRepositoryImpl(client: _clientWith(adapter));
      final plano = PlanoPartoModel.tryParse(_planoBody())!;

      final result = await repo.upsertPlanoParto(_gestacaoId, plano);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<SessionExpiredFailure>());
        case Success():
          fail('esperado SessionExpiredFailure');
      }
    });
  });
}
