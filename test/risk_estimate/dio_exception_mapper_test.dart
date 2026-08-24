import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/repositories/risk_estimate/dio_exception_mapper.dart';
import 'package:meu_bebe/app/repositories/risk_estimate/risk_estimate_failure.dart';

void main() {
  const mapper = RiskEstimateDioExceptionMapper();

  DioException e(DioExceptionType type, {int? statusCode, Object? data}) {
    final requestOptions = RequestOptions(path: '/api/v1/risk-estimate');
    return DioException(
      requestOptions: requestOptions,
      type: type,
      response: statusCode == null
          ? null
          : Response<dynamic>(
              requestOptions: requestOptions,
              statusCode: statusCode,
              data: data,
            ),
    );
  }

  group('RiskEstimateDioExceptionMapper', () {
    test('422 → ValidationFailure com details preservados', () {
      final f = mapper.map(
        e(
          DioExceptionType.badResponse,
          statusCode: 422,
          data: {
            'code': 'VALIDATION_ERROR',
            'message': 'Requisição inválida',
            'details': [
              {
                'loc': ['body', 'educacao', 'escolaridade'],
                'msg': 'inválido',
                'type': 'enum',
              },
            ],
          },
        ),
      );

      expect(f, isA<ValidationFailure>());
      expect(f.message, 'Requisição inválida');
      final validation = f as ValidationFailure;
      expect(validation.details, hasLength(1));
      expect(validation.details.first.loc, [
        'body',
        'educacao',
        'escolaridade',
      ]);
    });

    test('503 → ModelNotReadyFailure', () {
      final f = mapper.map(
        e(
          DioExceptionType.badResponse,
          statusCode: 503,
          data: {
            'error': {'code': 'MODEL_NOT_READY'},
          },
        ),
      );
      expect(f, isA<ModelNotReadyFailure>());
      expect(f.message, 'Modelo de inferência indisponível.');
    });

    test('500 → InferenceFailure', () {
      final f = mapper.map(
        e(
          DioExceptionType.badResponse,
          statusCode: 500,
          data: {
            'error': {'code': 'INFERENCE_ERROR'},
          },
        ),
      );
      expect(f, isA<InferenceFailure>());
      expect(f.message, 'Não foi possível calcular a estimativa.');
    });

    test('outros 5xx → ServiceUnavailableFailure', () {
      for (final status in [501, 502, 504, 505]) {
        final f = mapper.map(
          e(DioExceptionType.badResponse, statusCode: status),
        );
        expect(f, isA<ServiceUnavailableFailure>(), reason: 'status $status');
        expect(f.message, 'Serviço temporariamente indisponível.');
      }
    });

    test(
      '4xx (exceto 422) → CommunicationFailure genérico (sem vazar status)',
      () {
        final f = mapper.map(e(DioExceptionType.badResponse, statusCode: 400));
        expect(f, isA<CommunicationFailure>());
        expect(f.message, isNot(contains('400')));
        expect(f.message, isNot(contains('{')));
      },
    );

    test('timeouts (3 tipos) → TimeoutFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        final f = mapper.map(e(type));
        expect(f, isA<TimeoutFailure>(), reason: '$type');
        expect(f.message, 'Tempo de conexão com o serviço excedido.');
      }
    });

    test('connectionError → ConnectionFailure', () {
      final f = mapper.map(e(DioExceptionType.connectionError));
      expect(f, isA<ConnectionFailure>());
      expect(f.message, 'Não foi possível conectar ao serviço.');
    });

    test('badCertificate → ConnectionFailure (erro de segurança genérico)', () {
      expect(
        mapper.map(e(DioExceptionType.badCertificate)),
        isA<ConnectionFailure>(),
      );
    });

    test('cancel → RequestCancelledFailure (não é erro de servidor)', () {
      expect(
        mapper.map(e(DioExceptionType.cancel)),
        isA<RequestCancelledFailure>(),
      );
    });

    test('unknown → CommunicationFailure genérico', () {
      final f = mapper.map(e(DioExceptionType.unknown));
      expect(f, isA<CommunicationFailure>());
    });
  });
}
