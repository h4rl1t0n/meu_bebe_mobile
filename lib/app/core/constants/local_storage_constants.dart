sealed class LocalStorageConstants {
  static const accessToken = 'ACCESS_TOKEN_KEY';
  static const refreshToken = 'REFRESH_TOKEN_KEY';

  /// Flag do "Lembrar-me" (Login). `true` = manter a sessão entre aberturas;
  /// `false` = descartar os tokens na próxima abertura. Nunca armazena senha.
  static const rememberMe = 'REMEMBER_ME_KEY';
}
