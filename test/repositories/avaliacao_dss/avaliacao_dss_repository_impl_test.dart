import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/dss_schema.dart';
import 'package:meu_bebe/app/modules/formulario/models/formulario_data.dart';
import 'package:meu_bebe/app/repositories/avaliacao_dss/avaliacao_dss_repository_impl.dart';
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

Map<String, dynamic> _avaliacaoBody() => {
  'id': 'avaliacao-1',
  'schema_version': '1.13',
  'respostas': {
    'educacao': {'escolaridade': 'medio_completo'},
    'trabalho': {'empregado': true},
    'saneamento': {'fonte_agua': 'rede_publica'},
    'saude': {'cadastrada_ubs': true},
    'habitacao': {'tipo_moradia': 'casa'},
    'alimentacao': {'refeicoes_por_dia': 'tres'},
  },
  'created_at': '2026-08-29T00:00:00Z',
};

void main() {
  group('AvaliacaoDssRepositoryImpl.registrar', () {
    test('POST na rota correta + Success parseado', () async {
      final adapter = _RecordingAdapter((_) => _json(201, _avaliacaoBody()));
      final repo = AvaliacaoDssRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.registrar('gestacao-1', FormularioData.empty());

      switch (result) {
        case Success(success: final a):
          expect(a.id, 'avaliacao-1');
          expect(a.schemaVersion, '1.13');
          expect(a.respostas, isNotEmpty);
          expect(a.createdAt, '2026-08-29T00:00:00Z');
        case Error(error: final f):
          fail('esperado sucesso, veio $f');
      }

      expect(adapter.captured, hasLength(1));
      expect(adapter.captured.single.method, 'POST');
      expect(
        adapter.captured.single.path,
        '/api/v1/gestacoes/gestacao-1/avaliacoes-dss',
      );
    });

    test('gestacao_id viaja na ROTA — nunca no payload', () async {
      final adapter = _RecordingAdapter((_) => _json(201, _avaliacaoBody()));
      final repo = AvaliacaoDssRepositoryImpl(client: _clientWith(adapter));

      await repo.registrar('gestacao-7', FormularioData.empty());

      final sent = adapter.captured.single.data as Map<String, dynamic>;
      expect(sent.containsKey('gestacao_id'), isFalse);
      expect(adapter.captured.single.path, contains('/gestacao-7/'));
    });

    test('payload usa toMap(): schema_version 1.13 + 6 dimensões aninhadas',
        () async {
      final adapter = _RecordingAdapter((_) => _json(201, _avaliacaoBody()));
      final repo = AvaliacaoDssRepositoryImpl(client: _clientWith(adapter));

      await repo.registrar('gestacao-1', FormularioData.empty());

      final sent = adapter.captured.single.data as Map<String, dynamic>;
      expect(sent['schema_version'], DssSchema.schemaVersion);
      expect(DssSchema.schemaVersion, '1.13');
      for (final dim in const [
        'educacao',
        'trabalho',
        'saneamento',
        'saude',
        'habitacao',
        'alimentacao',
      ]) {
        expect(sent.containsKey(dim), isTrue, reason: 'dimensão ausente: $dim');
        expect(sent[dim], isA<Map<String, dynamic>>());
      }
      // NÃO é flat: nenhuma chave `dimensao.campo` no topo.
      expect(sent.keys.any((k) => k.contains('.')), isFalse);
    });

    test('marca requisição como autenticada (Authorization via interceptor)',
        () async {
      final adapter = _RecordingAdapter((_) => _json(201, _avaliacaoBody()));
      final repo = AvaliacaoDssRepositoryImpl(client: _clientWith(adapter));

      await repo.registrar('gestacao-1', FormularioData.empty());

      expect(adapter.captured.single.extra['DIO_AUTH_KEY'], isTrue);
    });

    test('payload NÃO contém campos de predição (operacional vs ML)', () async {
      final adapter = _RecordingAdapter((_) => _json(201, _avaliacaoBody()));
      final repo = AvaliacaoDssRepositoryImpl(client: _clientWith(adapter));

      await repo.registrar('gestacao-1', FormularioData.empty());

      final sent = adapter.captured.single.data as Map<String, dynamic>;
      final flattened = jsonEncode(sent).toLowerCase();
      for (final banned in const [
        'probability',
        'probabilidade',
        'risk',
        'risco',
        'class',
        'classe',
        'threshold',
        'recommendation',
        'recomendacao',
        'iv_dss',
        'cluster',
        'target',
      ]) {
        expect(
          flattened.contains(banned),
          isFalse,
          reason: 'payload operacional contém token de predição "$banned"',
        );
      }
    });

    test('resposta malformada → UnexpectedFailure (parse defensivo)', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(201, {
          'id': 123,
          'schema_version': '1.13',
          'respostas': {},
          'created_at': 'x',
        }),
      );
      final repo = AvaliacaoDssRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.registrar('gestacao-1', FormularioData.empty());

      switch (result) {
        case Error(error: final f):
          expect(f, isA<UnexpectedFailure>());
        case Success():
          fail('esperado UnexpectedFailure');
      }
    });

    test('401 → SessionExpiredFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(401, {'code': 'UNAUTHORIZED'}),
      );
      final repo = AvaliacaoDssRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.registrar('gestacao-1', FormularioData.empty());

      switch (result) {
        case Error(error: final f):
          expect(f, isA<SessionExpiredFailure>());
        case Success():
          fail('esperado SessionExpiredFailure');
      }
    });

    test('422 → ValidationFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(422, {'code': 'VALIDATION_ERROR'}),
      );
      final repo = AvaliacaoDssRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.registrar('gestacao-1', FormularioData.empty());

      switch (result) {
        case Error(error: final f):
          expect(f, isA<ValidationFailure>());
        case Success():
          fail('esperado ValidationFailure');
      }
    });

    test('500 → ServiceUnavailableFailure', () async {
      final adapter = _RecordingAdapter(
        (_) => _json(500, {'code': 'INTERNAL_ERROR'}),
      );
      final repo = AvaliacaoDssRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.registrar('gestacao-1', FormularioData.empty());

      switch (result) {
        case Error(error: final f):
          expect(f, isA<ServiceUnavailableFailure>());
        case Success():
          fail('esperado ServiceUnavailableFailure');
      }
    });

    test('offline (connectionError) → NetworkFailure', () async {
      final adapter = _RecordingAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      final repo = AvaliacaoDssRepositoryImpl(client: _clientWith(adapter));

      final result = await repo.registrar('gestacao-1', FormularioData.empty());

      switch (result) {
        case Error(error: final f):
          expect(f, isA<NetworkFailure>());
        case Success():
          fail('esperado NetworkFailure');
      }
    });
  });
}
