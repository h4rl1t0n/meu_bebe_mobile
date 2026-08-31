import 'package:shared_preferences/shared_preferences.dart';

import '../constants/local_storage_constants.dart';

/// Persistência local dos tokens de sessão (access + refresh).
///
/// Única fonte de leitura/escrita das credenciais de sessão em disco. NUNCA
/// expõe os tokens fora deste serviço (o [AuthInterceptor] e os controllers de
/// auth dependem apenas das operações aqui definidas).
final class TokenStorage {
  const TokenStorage();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> getAccessToken() async {
    return (await _prefs).getString(LocalStorageConstants.accessToken);
  }

  Future<String?> getRefreshToken() async {
    return (await _prefs).getString(LocalStorageConstants.refreshToken);
  }

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    final prefs = await _prefs;
    await prefs.setString(LocalStorageConstants.accessToken, accessToken);
    await prefs.setString(LocalStorageConstants.refreshToken, refreshToken);
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(LocalStorageConstants.accessToken);
    await prefs.remove(LocalStorageConstants.refreshToken);
  }

  /// `true` quando há um access token persistido (sessão localmente ativa).
  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Flag "Lembrar-me" persistida. `true` (default) mantém a sessão entre
  /// aberturas; `false` indica que a sessão deve ser descartada na próxima
  /// abertura. Persiste apenas um booleano — NUNCA a senha.
  Future<bool> getRememberMe() async {
    return (await _prefs).getBool(LocalStorageConstants.rememberMe) ?? true;
  }

  Future<void> setRememberMe(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(LocalStorageConstants.rememberMe, value);
  }
}
