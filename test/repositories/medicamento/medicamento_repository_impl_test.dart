import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/medicamento/medicamento_model.dart';
import 'package:meu_bebe/app/repositories/medicamento/medicamento_repository_impl.dart';
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

Map<String, dynamic> _medBody({String id = 'm1'}) => {
  'id': id,
  'nome': 'Ácido fólico',
  'dose': '5mg',
  'frequencia': '1 vez ao dia',
  'created_at': '2026-08-10T00:00:00Z',
  'updated_at': '2026-08-10T00:00:00Z',
};

const _med = MedicamentoModel(
  id: 'm1',
  nome: 'Ácido fólico',
  dose: '5mg',
  frequencia: '1 vez ao dia',
);

const _gestacaoId = 'ges-1';
const _basePath = '/api/v1/gestacoes/ges-1/medicamentos';

void main() {
  group('MedicamentoRepositoryImpl.listMedicamentos', () {
    test('200 → Success com lista parseada', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(200, [_medBody(), _medBody(id: 'm2')]),
      );
      final repo = MedicamentoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listMedicamentos(_gestacaoId);

      switch (result) {
        case Success(success: final list):
          expect(list, hasLength(2));
          expect(list.first.nome, 'Ácido fólico');
          expect(list.first.frequencia, '1 vez ao dia');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'GET');
      expect(adapter.captured.single.path, _basePath);
    });

    test('200 com lista vazia → Success([])', () async {
      final adapter = _RecordingAdapter((_) => _json(200, []));
      final repo = MedicamentoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listMedicamentos(_gestacaoId);

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
      final repo = MedicamentoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listMedicamentos(_gestacaoId);

      switch (result) {
        case Success(success: final list):
          expect(list, isEmpty);
        case Error(error: final f):
          fail('esperado Success([]), veio $f');
      }
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter((_) => _json(401, {'code': 'UNAUTHORIZED'}));
      final repo = MedicamentoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listMedicamentos(_gestacaoId);

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
      final repo = MedicamentoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.listMedicamentos(_gestacaoId);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<NetworkFailure>());
        case Success():
          fail('esperado NetworkFailure');
      }
    });
  });

  group('MedicamentoRepositoryImpl.createMedicamento', () {
    test('POST 201 → Success + payload sem id/gestacao_id/timestamps', () async {
      final adapter = _RecordingAdapter((_) => _json(201, _medBody()));
      final repo = MedicamentoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createMedicamento(_gestacaoId, _med);

      switch (result) {
        case Success(success: final m):
          expect(m.id, 'm1');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'POST');
      expect(adapter.captured.single.path, _basePath);
      final sent = adapter.captured.single.data as Map<String, dynamic>;
      expect(sent.containsKey('id'), isFalse);
      expect(sent.containsKey('gestacao_id'), isFalse);
      expect(sent.containsKey('created_at'), isFalse);
      expect(sent['nome'], 'Ácido fólico');
      expect(sent['dose'], '5mg');
      expect(sent['frequencia'], '1 vez ao dia');
    });

    test('422 → ValidationFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(422, {'code': 'VALIDATION_ERROR'}),
      );
      final repo = MedicamentoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.createMedicamento(_gestacaoId, _med);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<ValidationFailure>());
        case Success():
          fail('esperado ValidationFailure');
      }
    });
  });

  group('MedicamentoRepositoryImpl.updateMedicamento', () {
    test('PUT 200 → Success na rota /{id}', () async {
      final adapter = _RecordingAdapter((_) => _json(200, _medBody()));
      final repo = MedicamentoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.updateMedicamento(_gestacaoId, _med);

      switch (result) {
        case Success(success: final m):
          expect(m.id, 'm1');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'PUT');
      expect(adapter.captured.single.path, '$_basePath/m1');
    });

    test('404 → UnexpectedFailure (via mapper)', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(404, {'code': 'MEDICAMENTO_NOT_FOUND'}),
      );
      final repo = MedicamentoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.updateMedicamento(_gestacaoId, _med);

      switch (result) {
        case Error(error: final f):
          expect(f, isA<UnexpectedFailure>());
        case Success():
          fail('esperado erro');
      }
    });
  });

  group('MedicamentoRepositoryImpl.deleteMedicamento', () {
    test('DELETE 204 → Success(true)', () async {
      final adapter = _RecordingAdapter((_) => _json(204, <String, dynamic>{}));
      final repo = MedicamentoRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.deleteMedicamento(_gestacaoId, 'm1');

      switch (result) {
        case Success(success: final ok):
          expect(ok, isTrue);
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured.single.method, 'DELETE');
      expect(adapter.captured.single.path, '$_basePath/m1');
    });
  });
}
