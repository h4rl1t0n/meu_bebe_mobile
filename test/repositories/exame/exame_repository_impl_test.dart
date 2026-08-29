import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/exame/exame_model.dart';
import 'package:meu_bebe/app/repositories/exame/exame_repository_impl.dart';
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

Map<String, dynamic> _exameBody({String id = 'e1', String? categoria}) => {
  'id': id,
  'titulo': 'Ultrassom',
  'data_exame': '2025-10-01',
  'descricao': 'Obstétrico',
  'categoria': categoria,
  'created_at': '2025-10-01T00:00:00Z',
  'updated_at': '2025-10-01T00:00:00Z',
};

const _exame = ExameModel(
  id: 'e1',
  titulo: 'Ultrassom',
  dataExame: '2025-10-01',
  descricao: 'Obstétrico',
  categoria: 'ultrassom',
);

const _gestacaoId = 'ges-1';
const _basePath = '/api/v1/gestacoes/ges-1/exames';

void main() {
  group('ExameRepositoryImpl.listExames', () {
    test('200 → Success com lista parseada (categoria preservada)', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(200, [
          _exameBody(categoria: 'ultrassom'),
          _exameBody(id: 'e2', categoria: 'sangue'),
        ]),
      );
      final repo = ExameRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listExames(_gestacaoId);

      switch (result) {
        case Success(success: final list):
          expect(list, hasLength(2));
          expect(list.first.categoria, 'ultrassom');
          expect(list.last.categoria, 'sangue');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'GET');
      expect(adapter.captured.single.path, _basePath);
    });

    test('200 com lista vazia → Success([])', () async {
      final adapter = _RecordingAdapter((_) => _json(200, []));
      final repo = ExameRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listExames(_gestacaoId);

      switch (result) {
        case Success(success: final list):
          expect(list, isEmpty);
        case Error(error: final f):
          fail('esperado lista vazia, veio $f');
      }
    });

    test('404 → Success([]) e não erro', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(404, {'code': 'GESTACAO_NOT_FOUND'}),
      );
      final repo = ExameRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listExames(_gestacaoId);

      switch (result) {
        case Success(success: final list):
          expect(list, isEmpty);
        case Error(error: final f):
          fail('esperado Success([]), veio $f');
      }
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = ExameRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listExames(_gestacaoId);

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
      final repo = ExameRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listExames(_gestacaoId);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<NetworkFailure>());
        case Success():
          fail('esperado NetworkFailure');
      }
    });
  });

  group('ExameRepositoryImpl.createExame', () {
    test('POST 201 → Success + payload sem id/gestacao_id/timestamps', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(201, _exameBody(categoria: 'ultrassom')),
      );
      final repo = ExameRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createExame(_gestacaoId, _exame);

      switch (result) {
        case Success(success: final e):
          expect(e.id, 'e1');
          expect(e.categoria, 'ultrassom');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'POST');
      expect(adapter.captured.single.path, _basePath);
      final sent = adapter.captured.single.data as Map<String, dynamic>;
      expect(sent.containsKey('id'), isFalse);
      expect(sent.containsKey('gestacao_id'), isFalse);
      expect(sent.containsKey('created_at'), isFalse);
      expect(sent['titulo'], 'Ultrassom');
      expect(sent['data_exame'], '2025-10-01');
      expect(sent['categoria'], 'ultrassom');
    });

    test('422 → ValidationFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(422, {'code': 'VALIDATION_ERROR'}),
      );
      final repo = ExameRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createExame(_gestacaoId, _exame);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<ValidationFailure>());
        case Success():
          fail('esperado ValidationFailure');
      }
    });
  });

  group('ExameRepositoryImpl.updateExame', () {
    test('PUT 200 → Success na rota /{id}', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(200, _exameBody(categoria: 'ultrassom')),
      );
      final repo = ExameRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.updateExame(_gestacaoId, _exame);

      switch (result) {
        case Success(success: final e):
          expect(e.id, 'e1');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'PUT');
      expect(adapter.captured.single.path, '$_basePath/e1');
    });
  });

  group('ExameRepositoryImpl.deleteExame', () {
    test('DELETE 204 → Success(true)', () async {
      final adapter = _RecordingAdapter((_) => _json(204, <String, dynamic>{}));
      final repo = ExameRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.deleteExame(_gestacaoId, 'e1');

      switch (result) {
        case Success(success: final ok):
          expect(ok, isTrue);
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'DELETE');
      expect(adapter.captured.single.path, '$_basePath/e1');
    });
  });
}
