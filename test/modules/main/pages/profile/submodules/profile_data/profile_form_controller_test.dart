import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/main/pages/profile/submodules/profile_data/profile_form_controller.dart';

void main() {
  group('digitsOnly', () {
    test('remove pontuação de CPF/CNS', () {
      expect(digitsOnly('123.456.789-01'), '12345678901');
      expect(digitsOnly('123 456 789 012 345'), '123456789012345');
      expect(digitsOnly(null), '');
      expect(digitsOnly(''), '');
    });
  });

  group('dateToDisplay (ISO → DD/MM/YYYY)', () {
    test('converte corretamente', () {
      expect(dateToDisplay('1995-03-20'), '20/03/1995');
    });

    test('retorna vazio para null', () {
      expect(dateToDisplay(null), '');
    });
  });

  group('dateToIso (DD/MM/YYYY → ISO)', () {
    test('converte corretamente', () {
      expect(dateToIso('20/03/1995'), '1995-03-20');
      expect(dateToIso('1/2/1995'), '1995-02-01');
    });

    test('retorna null para vazio/inválido', () {
      expect(dateToIso(null), isNull);
      expect(dateToIso(''), isNull);
      expect(dateToIso('abc'), isNull);
    });

    test('round-trip é estável', () {
      expect(dateToIso(dateToDisplay('1995-03-20')), '1995-03-20');
    });
  });
}
