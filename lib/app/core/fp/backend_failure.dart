import 'package:dio/dio.dart';

import 'failure.dart';

/// Família de falhas das chamadas ao backend autenticado (auth/gestante/gestação).
///
/// Cada mensagem é amigável e NUNCA expõe status bruto, corpo JSON, HTML ou
/// stack trace da API (ver contrato de erros do backend: ``<500`` plano e
/// ``>=500`` envelopado).
sealed class BackendFailure extends Failure {
  const BackendFailure({super.message});
}

final class InvalidCredentialsFailure extends BackendFailure {
  const InvalidCredentialsFailure() : super(message: 'E-mail ou senha inválidos.');
}

final class AccountInactiveFailure extends BackendFailure {
  const AccountInactiveFailure()
    : super(message: 'Conta inativa. Entre em contato com o suporte.');
}

final class EmailAlreadyRegisteredFailure extends BackendFailure {
  const EmailAlreadyRegisteredFailure()
    : super(message: 'Este e-mail já está cadastrado.');
}

final class ActiveGestationExistsFailure extends BackendFailure {
  const ActiveGestationExistsFailure()
    : super(message: 'Já existe uma gestação ativa.');
}

final class ValidationFailure extends BackendFailure {
  const ValidationFailure()
    : super(message: 'Dados inválidos. Verifique os campos informados.');
}

final class SessionExpiredFailure extends BackendFailure {
  const SessionExpiredFailure()
    : super(message: 'Sessão expirada. Entre novamente.');
}

final class ServiceUnavailableFailure extends BackendFailure {
  const ServiceUnavailableFailure()
    : super(message: 'Serviço temporariamente indisponível.');
}

final class NetworkFailure extends BackendFailure {
  const NetworkFailure()
    : super(message: 'Não foi possível conectar ao servidor.');
}

final class UnexpectedFailure extends BackendFailure {
  const UnexpectedFailure()
    : super(message: 'Não foi possível concluir a operação.');
}

/// Converte um [DioException] numa [BackendFailure] específica.
///
/// 401 é mapeado como [SessionExpiredFailure] por padrão; o `login` trata o
/// caso específico de credenciais inválidas no próprio repositório.
final class BackendDioExceptionMapper {
  const BackendDioExceptionMapper();

  BackendFailure map(DioException exception) {
    final response = exception.response;
    if (response != null) {
      return _mapByStatus(response.statusCode ?? 0);
    }

    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate => const NetworkFailure(),
      DioExceptionType.cancel => const UnexpectedFailure(),
      DioExceptionType.badResponse || DioExceptionType.unknown => const NetworkFailure(),
    };
  }

  BackendFailure _mapByStatus(int status) {
    if (status == 401) return const SessionExpiredFailure();
    if (status == 403) return const AccountInactiveFailure();
    if (status == 409) return const EmailAlreadyRegisteredFailure();
    if (status == 422) return const ValidationFailure();
    if (status == 503) return const ServiceUnavailableFailure();
    if (status >= 500) return const ServiceUnavailableFailure();
    return const UnexpectedFailure();
  }
}
