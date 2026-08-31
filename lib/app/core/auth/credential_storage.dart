import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contrato de persistência das credenciais "Lembrar-me" (e-mail + senha).
///
/// A senha fica APENAS em armazenamento seguro do sistema (Keychain no iOS,
/// Keystore/EncryptedSharedPreferences no Android, DPAPI no Windows) via
/// `flutter_secure_storage` — NUNCA em SharedPreferences, arquivo, JSON,
/// SQLite, log ou qualquer armazenamento plaintext.
///
/// Abstraído para permitir fakes nos testes (que rodam na VM do Dart e não
/// têm canais nativos do plugin).
abstract class CredentialStorage {
  Future<String?> getEmail();
  Future<String?> getPassword();
  Future<void> save({required String email, required String password});
  Future<void> clear();
}

/// Implementação real sobre `flutter_secure_storage`.
final class SecureCredentialStorage implements CredentialStorage {
  SecureCredentialStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _emailKey = 'REMEMBERED_EMAIL_KEY';
  static const _passwordKey = 'REMEMBERED_PASSWORD_KEY';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getEmail() => _storage.read(key: _emailKey);

  @override
  Future<String?> getPassword() => _storage.read(key: _passwordKey);

  @override
  Future<void> save({required String email, required String password}) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
