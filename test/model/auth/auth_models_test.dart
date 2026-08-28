import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/auth/auth_models.dart';

void main() {
  group('UserResponseModel.tryParse', () {
    test('parse válido do contrato FASE 8C', () {
      final user = UserResponseModel.tryParse({
        'id': 'user-1',
        'email': 'maria@example.com',
        'is_active': true,
      });

      expect(user, isNotNull);
      expect(user!.id, 'user-1');
      expect(user.email, 'maria@example.com');
      expect(user.isActive, isTrue);
    });

    test('retorna null para corpo inválido', () {
      expect(UserResponseModel.tryParse(null), isNull);
      expect(UserResponseModel.tryParse('não é map'), isNull);
      expect(UserResponseModel.tryParse({'email': 'a@b.com'}), isNull);
      expect(
        UserResponseModel.tryParse({
          'id': 'user-1',
          'email': 'a@b.com',
          'is_active': 'sim',
        }),
        isNull,
      );
    });
  });

  group('TokenResponseModel.tryParse', () {
    test('parse válido', () {
      final token = TokenResponseModel.tryParse({
        'user': {'id': 'user-1', 'email': 'maria@example.com', 'is_active': true},
        'access_token': 'access',
        'refresh_token': 'refresh',
      });

      expect(token, isNotNull);
      expect(token!.accessToken, 'access');
      expect(token.refreshToken, 'refresh');
      expect(token.user.email, 'maria@example.com');
    });

    test('retorna null se faltar token ou user', () {
      expect(TokenResponseModel.tryParse(null), isNull);
      expect(
        TokenResponseModel.tryParse({
          'access_token': 'access',
          'refresh_token': 'refresh',
        }),
        isNull,
      );
      expect(
        TokenResponseModel.tryParse({
          'user': {'id': 'user-1', 'email': 'a@b.com', 'is_active': true},
          'access_token': 'access',
        }),
        isNull,
      );
    });
  });
}
