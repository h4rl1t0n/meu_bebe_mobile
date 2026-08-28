import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../env.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/privacy_log_interceptor.dart';

/// Cliente HTTP do backend autenticado (``BACKEND_BASE_URL``).
///
/// Usa [PrivacyLogInterceptor] (nunca registra corpo/cabeçalhos) — o login e a
/// renovação transportam credenciais/tokens, portanto o corpo da requisição e
/// da resposta jamais pode ir ao log. O [AuthInterceptor] injeta o
/// ``Authorization`` e faz a renovação transparente em 401.
final class RestClient extends DioForNative {
  RestClient()
    : super(
        BaseOptions(
          baseUrl: Env.backendBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ) {
    interceptors.addAll([
      PrivacyLogInterceptor(),
      AuthInterceptor(client: this),
    ]);
  }

  RestClient get auth {
    options.extra['DIO_AUTH_KEY'] = true;
    return this;
  }

  RestClient get unAuth {
    options.extra['DIO_AUTH_KEY'] = false;
    return this;
  }
}
