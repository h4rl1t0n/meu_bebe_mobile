import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/vacina/vacina_model.dart';
import 'package:meu_bebe/app/repositories/vacina/vacina_repository_impl.dart';
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

Map<String, dynamic> _vacBody({String id = 'v1', bool aplicada = false}) => {
  'id': id,
  'nome': 'dTpa',
  'aplicada': aplicada,
  'created_at': '2026-08-10T00:00:00Z',
  'updated_at': '2026-08-10T00:00:00Z',
};

const _vac = VacinaModel(id: 'v1', nome: 'dTpa', aplicada: true);

const _gestacaoId = 'ges-1';
const _basePath = '/api/v1/gestacoes/ges-1/vacinas';

void main() {
  group('VacinaRepositoryImpl.listVacinas', () {
    test('200 → Success com lista parseada (aplicada preservado)', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(200, [_vacBody(), _vacBody(id: 'v2', aplicada: true)]),
      );
      final repo = VacinaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listVacinas(_gestacaoId);

      switch (result) {
        case Success(success: final list):
          expect(list, hasLength(2));
          expect(list.first.nome, 'dTpa');
          expect(list.first.aplicada, isFalse);
          expect(list.last.aplicada, isTrue);
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'GET');
      expect(adapter.captured.single.path, _basePath);
    });

    test('404 → Success([])', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(404, {'code': 'GESTACAO_NOT_FOUND'}),
      );
      final repo = VacinaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listVacinas(_gestacaoId);

      switch (result) {
        case Success(success: final list):
          expect(list, isEmpty);
        case Error(error: final f):
          fail('esperado Success([]), veio $f');
      }
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = VacinaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listVacinas(_gestacaoId);

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
      final repo = VacinaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listVacinas(_gestacaoId);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<NetworkFailure>());
        case Success():
          fail('esperado NetworkFailure');
      }
    });
  });

  group('VacinaRepositoryImpl.createVacina', () {
    test('POST 201 → Success + payload sem id/gestacao_id/timestamps', () async {
      final adapter = _RecordingAdapter((_) => _json(201, _vacBody(aplicada: true)));
      final repo = VacinaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createVacina(_gestacaoId, _vac);

      switch (result) {
        case Success(success: final v):
          expect(v.id, 'v1');
          expect(v.aplicada, isTrue);
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'POST');
      expect(adapter.captured.single.path, _basePath);
      final sent = adapter.captured.single.data as Map<String, dynamic>;
      expect(sent.containsKey('id'), isFalse);
      expect(sent.containsKey('gestacao_id'), isFalse);
      expect(sent.containsKey('created_at'), isFalse);
      expect(sent, {'nome': 'dTpa', 'aplicada': true});
    });

    test('422 → ValidationFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(422, {'code': 'VALIDATION_ERROR'}),
      );
      final repo = VacinaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createVacina(_gestacaoId, _vac);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<ValidationFailure>());
        case Success():
          fail('esperado ValidationFailure');
      }
    });
  });

  group('VacinaRepositoryImpl.updateVacina', () {
    test('PUT 200 → Success na rota /{uuid} (nunca índice)', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(200, _vacBody(id: 'uuid-real-abc', aplicada: true)),
      );
      final repo = VacinaRepositoryImpl(client: _clientWith(adapter));

      const vac = VacinaModel(id: 'uuid-real-abc', nome: 'dTpa', aplicada: true);
      final result = await repo.updateVacina(_gestacaoId, vac);

      switch (result) {
        case Success(success: final v):
          expect(v.id, 'uuid-real-abc');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'PUT');
      expect(adapter.captured.single.path, '$_basePath/uuid-real-abc');
    });
  });
}
