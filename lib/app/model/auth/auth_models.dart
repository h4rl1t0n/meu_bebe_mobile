/// Modelos de resposta do backend de autenticação (contrato congelado FASE 8C).
///
/// Parsing defensivo: `tryParse` retorna `null` (nunca lança) quando o corpo
/// não corresponde ao contrato. Os campos de data são mantidos como `String?`
/// para não acoplar a desserialização a um formato de timestamp específico.
library;

class UserResponseModel {
  final String id;
  final String email;
  final bool isActive;

  const UserResponseModel({
    required this.id,
    required this.email,
    required this.isActive,
  });

  static UserResponseModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final id = data['id'];
    final email = data['email'];
    final isActive = data['is_active'];
    if (id is! String || email is! String || isActive is! bool) return null;

    return UserResponseModel(id: id, email: email, isActive: isActive);
  }
}

class TokenResponseModel {
  final UserResponseModel user;
  final String accessToken;
  final String refreshToken;

  const TokenResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  static TokenResponseModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final user = UserResponseModel.tryParse(data['user']);
    final accessToken = data['access_token'];
    final refreshToken = data['refresh_token'];
    if (user == null || accessToken is! String || refreshToken is! String) {
      return null;
    }

    return TokenResponseModel(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
