import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/consulta/consulta_model.dart';
import 'package:meu_bebe/app/repositories/consulta/consulta_repository_impl.dart';
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

Map<String, dynamic> _consultaBody({String id = 'c1'}) => {
  'id': id,
  'titulo': 'Pré-natal',
  'data_consulta': '2025-11-01',
  'descricao': 'Rotina',
  'created_at': '2025-11-01T00:00:00Z',
  'updated_at': '2025-11-01T00:00:00Z',
};

const _consulta = ConsultaModel(
  id: 'c1',
  titulo: 'Pré-natal',
  dataConsulta: '2025-11-01',
  descricao: 'Rotina',
);

const _gestacaoId = 'ges-1';
const _basePath = '/api/v1/gestacoes/ges-1/consultas';

void main() {
  group('ConsultaRepositoryImpl.listConsultas', () {
    test('200 → Success com lista parseada', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(200, [_consultaBody(), _consultaBody(id: 'c2')]),
      );
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listConsultas(_gestacaoId);

      switch (result) {
        case Success(success: final list):
          expect(list, hasLength(2));
          expect(list.first.titulo, 'Pré-natal');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'GET');
      expect(adapter.captured.single.path, _basePath);
    });

    test('200 com lista vazia → Success([])', () async {
      final adapter = _RecordingAdapter((_) => _json(200, []));
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listConsultas(_gestacaoId);

      switch (result) {
        case Success(success: final list):
          expect(list, isEmpty);
        case Error(error: final f):
          fail('esperado lista vazia, veio $f');
      }
    });

    test('404 (gestação inexistente/alheia) → Success([]) e não erro', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(404, {'code': 'GESTACAO_NOT_FOUND'}),
      );
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listConsultas(_gestacaoId);

      switch (result) {
        case Success(success: final list):
          expect(list, isEmpty);
        case Error(error: final f):
          fail('esperado Success([]), veio $f');
      }
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listConsultas(_gestacaoId);

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
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listConsultas(_gestacaoId);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<NetworkFailure>());
        case Success():
          fail('esperado NetworkFailure');
      }
    });
  });

  group('ConsultaRepositoryImpl.createConsulta', () {
    test('POST 201 → Success + payload sem id/gestacao_id/timestamps', () async {
      final adapter = _RecordingAdapter((_) => _json(201, _consultaBody()));
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createConsulta(_gestacaoId, _consulta);

      switch (result) {
        case Success(success: final c):
          expect(c.id, 'c1');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'POST');
      expect(adapter.captured.single.path, _basePath);
      final sent = adapter.captured.single.data as Map<String, dynamic>;
      expect(sent.containsKey('id'), isFalse);
      expect(sent.containsKey('gestacao_id'), isFalse);
      expect(sent.containsKey('created_at'), isFalse);
      expect(sent['titulo'], 'Pré-natal');
      expect(sent['data_consulta'], '2025-11-01');
    });

    test('422 → ValidationFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(422, {'code': 'VALIDATION_ERROR'}),
      );
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createConsulta(_gestacaoId, _consulta);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<ValidationFailure>());
        case Success():
          fail('esperado ValidationFailure');
      }
    });

    test('404 → UnexpectedFailure (não vaza JSON/código)', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(404, {'code': 'GESTACAO_NOT_FOUND'}),
      );
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createConsulta(_gestacaoId, _consulta);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<UnexpectedFailure>());
        case Success():
          fail('esperado UnexpectedFailure');
      }
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createConsulta(_gestacaoId, _consulta);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<SessionExpiredFailure>());
        case Success():
          fail('esperado SessionExpiredFailure');
      }
    });
  });

  group('ConsultaRepositoryImpl.updateConsulta', () {
    test('PUT 200 → Success na rota /{id}', () async {
      final adapter = _RecordingAdapter((_) => _json(200, _consultaBody()));
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.updateConsulta(_gestacaoId, _consulta);

      switch (result) {
        case Success(success: final c):
          expect(c.id, 'c1');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'PUT');
      expect(adapter.captured.single.path, '$_basePath/c1');
    });
  });

  group('ConsultaRepositoryImpl.deleteConsulta', () {
    test('DELETE 204 → Success(true)', () async {
      final adapter = _RecordingAdapter((_) => _json(204, <String, dynamic>{}));
      final repo = ConsultaRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.deleteConsulta(_gestacaoId, 'c1');

      switch (result) {
        case Success(success: final ok):
          expect(ok, isTrue);
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'DELETE');
      expect(adapter.captured.single.path, '$_basePath/c1');
    });
  });
}
