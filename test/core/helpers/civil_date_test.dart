import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/helpers/civil_date.dart';

void main() {
  group('civilDateDisplayToIso', () {
    test('DD/MM/YYYY válido → ISO', () {
      expect(civilDateDisplayToIso('01/11/2025'), '2025-11-01');
      expect(civilDateDisplayToIso('15/02/2026'), '2026-02-15');
    });

    test('data futura é permitida (consulta/exame pode ser agendado)', () {
      expect(civilDateDisplayToIso('31/12/2099'), '2099-12-31');
    });

    test('data inexistente (99/99/2025) → null', () {
      expect(civilDateDisplayToIso('99/99/2025'), isNull);
    });

    test('data inválida (31/02/2025) → null', () {
      expect(civilDateDisplayToIso('31/02/2025'), isNull);
    });

    test('vazio → null', () {
      expect(civilDateDisplayToIso(null), isNull);
      expect(civilDateDisplayToIso(''), isNull);
      expect(civilDateDisplayToIso('   '), isNull);
    });

    test('formato errado → null', () {
      expect(civilDateDisplayToIso('2025-11-01'), isNull);
      expect(civilDateDisplayToIso('abc'), isNull);
    });
  });

  group('civilDateIsoToDisplay', () {
    test('ISO → DD/MM/YYYY', () {
      expect(civilDateIsoToDisplay('2025-11-01'), '01/11/2025');
    });

    test('vazio → string vazia', () {
      expect(civilDateIsoToDisplay(null), '');
      expect(civilDateIsoToDisplay(''), '');
    });

    test('formato inválido → string vazia', () {
      expect(civilDateIsoToDisplay('01/11/2025'), '');
      expect(civilDateIsoToDisplay('abc'), '');
    });
  });

  group('civilDateTodayIso', () {
    test('retorna hoje em ISO válido', () {
      final iso = civilDateTodayIso();
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(iso), isTrue);
      expect(DateTime.tryParse(iso), isNotNull);
    });
  });
}
