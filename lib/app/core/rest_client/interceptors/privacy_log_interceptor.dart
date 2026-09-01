import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Logger de rede que NUNCA registra payload.
///
/// O questionário DSS transporta dados sociais e de saúde sensíveis; por isso
/// este interceptor registra apenas método, caminho, status, duração e o tipo
/// genérico do erro — sem corpo de requisição/resposta e sem cabeçalhos
/// sensíveis (ex.: `Authorization`).
final class PrivacyLogInterceptor extends Interceptor {
  final _starts = <RequestOptions, DateTime>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _starts[options] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, response.statusCode, null);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode, err.type);
    handler.next(err);
  }

  void _log(RequestOptions options, int? status, DioExceptionType? error) {
    final start = _starts.remove(options);
    final duration = start == null ? null : DateTime.now().difference(start);

    final buffer = StringBuffer(options.method)
      ..write(' ')
      ..write(options.path);

    if (status != null) buffer.write(' status=$status');
    if (error != null) buffer.write(' type=${error.name}');
    if (duration != null) buffer.write(' ${duration.inMilliseconds}ms');

    developer.log(buffer.toString(), name: 'HTTP');
  }
}
