import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/historico_obstetrico/historico_obstetrico_model.dart';
import 'package:meu_bebe/app/repositories/historico_obstetrico/historico_obstetrico_repository_impl.dart';
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

Map<String, dynamic> _historicoBody() => {
  'id': 'hist-1',
  'pregnancy_number': 2,
  'given_birth_number': 1,
  'abortions_number': 0,
  'created_at': '2025-11-01T00:00:00Z',
  'updated_at': '2025-11-01T00:00:00Z',
};

const _historico = HistoricoObstetricoModel(
  id: 'hist-1',
  pregnancyNumber: 2,
  givenBirthNumber: 1,
  abortionsNumber: 0,
);

void main() {
  group('HistoricoObstetricoRepositoryImpl.getHistorico', () {
    test('200 → Success com resposta parseada', () async {
      final adapter = _RecordingAdapter((_) => _json(200, _historicoBody()));
      final repo = HistoricoObstetricoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.getHistorico();

      switch (result) {
        case Success(success: final h):
          expect(h, isNotNull);
          expect(h!.id, 'hist-1');
          expect(h.pregnancyNumber, 2);
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'GET');
      expect(
        adapter.captured.single.path,
        '/api/v1/gestantes/me/historico-obstetrico',
      );
    });

    test('404 → Success(null) (ainda não preenchido)', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(404, {'code': 'OBSTETRIC_HISTORY_NOT_FOUND'}),
      );
      final repo = HistoricoObstetricoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.getHistorico();

      switch (result) {
        case Success(success: final h):
          expect(h, isNull);
        case Error(error: final f):
          fail('esperado Success(null), veio $f');
      }
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = HistoricoObstetricoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.getHistorico();

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
      final repo = HistoricoObstetricoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.getHistorico();

      switch (result) {
        case Error(error: final f):
          expect(f, isA<NetworkFailure>());
        case Success():
          fail('esperado NetworkFailure');
      }
    });
  });

  group('HistoricoObstetricoRepositoryImpl.saveHistorico', () {
    test('PUT upsert → Success', () async {
      final adapter = _RecordingAdapter((_) => _json(200, _historicoBody()));
      final repo = HistoricoObstetricoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.saveHistorico(_historico);

      switch (result) {
        case Success(success: final h):
          expect(h.id, 'hist-1');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'PUT');
      expect(
        adapter.captured.single.path,
        '/api/v1/gestantes/me/historico-obstetrico',
      );
    });

    test('payload não envia id nem timestamps', () async {
      final adapter = _RecordingAdapter((_) => _json(200, _historicoBody()));
      final repo = HistoricoObstetricoRepositoryImpl(client: _clientWith(adapter));

      await repo.saveHistorico(_historico);

      final sent = adapter.captured.single.data as Map<String, dynamic>;
      expect(sent.containsKey('id'), isFalse);
      expect(sent.containsKey('created_at'), isFalse);
      expect(sent.containsKey('updated_at'), isFalse);
      expect(sent['pregnancy_number'], 2);
      expect(sent['given_birth_number'], 1);
      expect(sent['abortions_number'], 0);
    });

    test('422 → ValidationFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(422, {'code': 'VALIDATION_ERROR'}),
      );
      final repo = HistoricoObstetricoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.saveHistorico(_historico);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<ValidationFailure>());
        case Success():
          fail('esperado ValidationFailure');
      }
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = HistoricoObstetricoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.saveHistorico(_historico);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<SessionExpiredFailure>());
        case Success():
          fail('esperado SessionExpiredFailure');
      }
    });
  });
}
