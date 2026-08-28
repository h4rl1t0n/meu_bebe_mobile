import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/repositories/gestacao/gestacao_repository_impl.dart';
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

ResponseBody _json(int status, Map<String, dynamic> body) => ResponseBody(
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

Map<String, dynamic> _gestacaoBody() => {
  'id': 'gestacao-1',
  'data_ultima_menstruacao': '2025-11-01',
  'local_pre_natal': 'UBS Central',
  'profissional_pre_natal': 'Dra. Ana',
  'contato_local_pre_natal': '(92) 99999-0000',
  'ended_at': null,
  'created_at': '2025-11-01T00:00:00Z',
  'updated_at': '2025-11-01T00:00:00Z',
};

const _gestacao = GestacaoModel(
  id: 'gestacao-1',
  dataUltimaMenstruacao: '2025-11-01',
  localPreNatal: 'UBS Central',
  profissionalPreNatal: 'Dra. Ana',
  contatoLocalPreNatal: '(92) 99999-0000',
);

void main() {
  group('GestacaoRepositoryImpl.createGestacao', () {
    test('POST /api/v1/gestacoes → Success com resposta parseada', () async {
      final adapter = _RecordingAdapter((_) => _json(201, _gestacaoBody()));
      final repo = GestacaoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createGestacao(_gestacao);

      switch (result) {
        case Success(success: final g):
          expect(g.id, 'gestacao-1');
          expect(g.dataUltimaMenstruacao, '2025-11-01');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured, hasLength(1));
      expect(adapter.captured.single.method, 'POST');
      expect(adapter.captured.single.path, '/api/v1/gestacoes');
    });

    test('payload não envia id/ended_at/timestamps', () async {
      final adapter = _RecordingAdapter((_) => _json(201, _gestacaoBody()));
      final repo = GestacaoRepositoryImpl(client: _clientWith(adapter));

      await repo.createGestacao(_gestacao);

      final sent = adapter.captured.single.data as Map<String, dynamic>;
      expect(sent.containsKey('id'), isFalse);
      expect(sent.containsKey('gestante_id'), isFalse);
      expect(sent.containsKey('ended_at'), isFalse);
      expect(sent.containsKey('created_at'), isFalse);
      expect(sent['data_ultima_menstruacao'], '2025-11-01');
      expect(sent['local_pre_natal'], 'UBS Central');
    });

    test('409 → ActiveGestationExistsFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(409, {'code': 'ACTIVE_GESTATION_EXISTS'}),
      );
      final repo = GestacaoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createGestacao(_gestacao);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<ActiveGestationExistsFailure>());
        case Success():
          fail('esperado ActiveGestationExistsFailure');
      }
    });

    test('422 → ValidationFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(422, {'code': 'VALIDATION_ERROR'}),
      );
      final repo = GestacaoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createGestacao(_gestacao);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<ValidationFailure>());
        case Success():
          fail('esperado ValidationFailure');
      }
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = GestacaoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createGestacao(_gestacao);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<SessionExpiredFailure>());
        case Success():
          fail('esperado SessionExpiredFailure');
      }
    });

    test('offline (connectionError) → NetworkFailure', () async {
      final adapter = _RecordingAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      final repo = GestacaoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createGestacao(_gestacao);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<NetworkFailure>());
        case Success():
          fail('esperado NetworkFailure');
      }
    });
  });

  group('GestacaoRepositoryImpl.updateGestacao', () {
    test('PUT /api/v1/gestacoes/{id} → Success', () async {
      final adapter = _RecordingAdapter((_) => _json(200, _gestacaoBody()));
      final repo = GestacaoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.updateGestacao(_gestacao);

      switch (result) {
        case Success(success: final g):
          expect(g.id, 'gestacao-1');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'PUT');
      expect(adapter.captured.single.path, '/api/v1/gestacoes/gestacao-1');
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = GestacaoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.updateGestacao(_gestacao);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<SessionExpiredFailure>());
        case Success():
          fail('esperado SessionExpiredFailure');
      }
    });
  });
}
