import 'package:flutter_modular/flutter_modular.dart';

import '../../app_module.dart';
import 'token_storage.dart';

/// Gerencia o encerramento de sessão quando a renovação falha definitivamente.
///
/// Centraliza a reação a "sessão expirada": limpa os tokens persistidos e
/// redireciona UMA única vez para o Login, protegido contra navegações
/// duplicadas/loops. Não acopla o [AuthInterceptor] a `BuildContext` — a
/// navegação usa o roteador global do Modular.
final class SessionManager {
  final TokenStorage storage;
  final Future<void> Function() _navigateToLogin;

  SessionManager({
    TokenStorage? storage,
    Future<void> Function()? navigateToLogin,
  })  : storage = storage ?? const TokenStorage(),
        _navigateToLogin = navigateToLogin ?? _defaultNavigateToLogin;

  static Future<void> _defaultNavigateToLogin() async {
    await Modular.to.pushReplacementNamed(routeLogin);
  }

  bool _handlingExpiredSession = false;

  /// Limpa os tokens e volta ao Login (apenas a primeira chamada vence).
  Future<void> handleSessionExpired() async {
    if (_handlingExpiredSession) return;
    _handlingExpiredSession = true;
    try {
      await storage.clear();
      await _navigateToLogin();
    } finally {
      _handlingExpiredSession = false;
    }
  }
}
