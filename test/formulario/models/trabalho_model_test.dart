import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/trabalho/trabalho_model.dart';

void main() {
  group('TrabalhoModel', () {
    test('toMap serializa motivo_desemprego e impacto_gestacao_trabalho por código canônico', () {
      const model = TrabalhoModel(
        empregado: false,
        motivoDesemprego: 'cuidado_casa_filhos',
        recebeBeneficioSocial: true,
        impactoGestacaoTrabalho: 'reduziu_jornada',
      );

      final map = model.toMap();

      expect(map['empregado'], isFalse);
      expect(map['motivo_desemprego'], 'cuidado_casa_filhos');
      expect(map['recebe_beneficio_social'], isTrue);
      expect(map['impacto_gestacao_trabalho'], 'reduziu_jornada');
    });

    test('fromMap/toMap preserva os códigos categóricos (round-trip)', () {
      const model = TrabalhoModel(
        empregado: false,
        motivoDesemprego: 'gestacao',
        recebeBeneficioSocial: false,
        impactoGestacaoTrabalho: 'demitida',
      );

      final restored = TrabalhoModel.fromMap(model.toMap());

      expect(restored, model);
      expect(restored.motivoDesemprego, 'gestacao');
      expect(restored.impactoGestacaoTrabalho, 'demitida');
    });

    test('fromMap trata campos ausentes como null (sem perda de simetria)', () {
      final model = TrabalhoModel.fromMap(const {'empregado': false});

      expect(model.empregado, isFalse);
      expect(model.motivoDesemprego, isNull);
      expect(model.impactoGestacaoTrabalho, isNull);
    });

    test('empty() começa desempregada e sem categorias', () {
      final model = TrabalhoModel.empty();

      expect(model.empregado, isFalse);
      expect(model.motivoDesemprego, isNull);
      expect(model.impactoGestacaoTrabalho, isNull);
    });
  });
}
