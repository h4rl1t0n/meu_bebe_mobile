import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/educacao/educacao_model.dart';

void main() {
  group('EducacaoModel', () {
    test('toMap usa códigos canônicos (nunca rótulos exibidos)', () {
      const model = EducacaoModel(
        estuda: true,
        escolaridade: 'medio_completo',
        interrompeuEstudos: false,
        dificuldadesEducacao: ['falta_dinheiro', 'distancia'],
        entendeOrientacoes: true,
        fezCursoExtracurricular: true,
      );

      final map = model.toMap();

      expect(map['estuda_atualmente'], isTrue);
      expect(map['escolaridade'], 'medio_completo');
      expect(map['interrompeu_estudos_gestacao'], isFalse);
      expect(map['dificuldades_educacao'], ['falta_dinheiro', 'distancia']);
      expect(map['entende_orientacoes_saude'], isTrue);
      expect(map['fez_curso_extracurricular'], isTrue);
    });

    test('fromMap/toMap preserva a múltipla escolha (round-trip)', () {
      const model = EducacaoModel(
        estuda: false,
        escolaridade: 'superior',
        interrompeuEstudos: true,
        dificuldadesEducacao: ['gravidez', 'trabalho', 'outro'],
        entendeOrientacoes: false,
        fezCursoExtracurricular: false,
      );

      final restored = EducacaoModel.fromMap(model.toMap());

      expect(restored, model);
      expect(restored.dificuldadesEducacao, ['gravidez', 'trabalho', 'outro']);
    });

    test('fromMap trata campos ausentes como vazio/null', () {
      final model = EducacaoModel.fromMap(const {});

      expect(model.escolaridade, isNull);
      expect(model.dificuldadesEducacao, isEmpty);
      expect(model.estuda, isFalse);
    });

    test('empty() começa sem escolaridade e sem dificuldades', () {
      final model = EducacaoModel.empty();

      expect(model.escolaridade, isNull);
      expect(model.dificuldadesEducacao, isEmpty);
    });
  });
}
