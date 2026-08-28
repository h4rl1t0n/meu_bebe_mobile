import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';

void main() {
  const mapper = BackendDioExceptionMapper();

  DioException e(DioExceptionType type, {int? statusCode}) {
    final requestOptions = RequestOptions(path: '/api/v1/auth/login');
    return DioException(
      requestOptions: requestOptions,
      type: type,
      response: statusCode == null
          ? null
          : Response<dynamic>(
              requestOptions: requestOptions,
              statusCode: statusCode,
            ),
    );
  }

  group('BackendDioExceptionMapper (status HTTP)', () {
    test('401 → SessionExpiredFailure', () {
      expect(
        mapper.map(e(DioExceptionType.badResponse, statusCode: 401)),
        isA<SessionExpiredFailure>(),
      );
    });

    test('403 → AccountInactiveFailure', () {
      expect(
        mapper.map(e(DioExceptionType.badResponse, statusCode: 403)),
        isA<AccountInactiveFailure>(),
      );
    });

    test('409 → EmailAlreadyRegisteredFailure', () {
      expect(
        mapper.map(e(DioExceptionType.badResponse, statusCode: 409)),
        isA<EmailAlreadyRegisteredFailure>(),
      );
    });

    test('422 → ValidationFailure', () {
      expect(
        mapper.map(e(DioExceptionType.badResponse, statusCode: 422)),
        isA<ValidationFailure>(),
      );
    });

    test('503 → ServiceUnavailableFailure', () {
      expect(
        mapper.map(e(DioExceptionType.badResponse, statusCode: 503)),
        isA<ServiceUnavailableFailure>(),
      );
    });

    test('>=500 → ServiceUnavailableFailure', () {
      for (final status in [500, 502, 504]) {
        expect(
          mapper.map(e(DioExceptionType.badResponse, statusCode: status)),
          isA<ServiceUnavailableFailure>(),
          reason: 'status $status',
        );
      }
    });

    test('outros 4xx → UnexpectedFailure (sem vazar status)', () {
      final f = mapper.map(e(DioExceptionType.badResponse, statusCode: 400));
      expect(f, isA<UnexpectedFailure>());
      expect(f.message, isNot(contains('400')));
    });
  });

  group('BackendDioExceptionMapper (rede)', () {
    test('connectionError → NetworkFailure', () {
      expect(
        mapper.map(e(DioExceptionType.connectionError)),
        isA<NetworkFailure>(),
      );
    });

    test('badCertificate → NetworkFailure', () {
      expect(
        mapper.map(e(DioExceptionType.badCertificate)),
        isA<NetworkFailure>(),
      );
    });

    test('timeouts → NetworkFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        expect(mapper.map(e(type)), isA<NetworkFailure>(), reason: '$type');
      }
    });
  });

  group('BackendFailure (mensagens amigáveis, sem vazar detalhes)', () {
    test('mensagens não contêm status/corpo/JSON', () {
      const failures = [
        SessionExpiredFailure(),
        AccountInactiveFailure(),
        EmailAlreadyRegisteredFailure(),
        ValidationFailure(),
        ServiceUnavailableFailure(),
        NetworkFailure(),
        UnexpectedFailure(),
        InvalidCredentialsFailure(),
      ];

      for (final f in failures) {
        expect(f.message, isNotEmpty);
        expect(f.message, isNot(contains('{')));
        expect(f.message, isNot(contains('status')));
      }
    });
  });
}
