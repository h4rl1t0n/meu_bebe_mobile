import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/educacao/educacao_model.dart';

void main() {
  group('EducacaoModel', () {
    test('toMap usa códigos canônicos e a nova chave da situação dos estudos (sem chaves legadas)', () {
      const model = EducacaoModel(
        estuda: true,
        escolaridade: 'medio_completo',
        situacaoEstudosGestacao: 'nao_interrompeu',
        dificuldadesEducacao: ['falta_dinheiro', 'distancia'],
        entendeOrientacoes: true,
        fezCursoQualificacaoProfissional: true,
      );

      final map = model.toMap();

      expect(map['estuda_atualmente'], isTrue);
      expect(map['escolaridade'], 'medio_completo');
      expect(map['situacao_estudos_gestacao'], 'nao_interrompeu');
      expect(map['dificuldades_educacao'], ['falta_dinheiro', 'distancia']);
      expect(map['entende_orientacoes_saude'], isTrue);
      expect(map['fez_curso_qualificacao_profissional'], isTrue);
      expect(map.containsKey('fez_curso_extracurricular'), isFalse);
      expect(map.containsKey('interrompeu_estudos_gestacao'), isFalse);
    });

    test('os três códigos canônicos de situacao_estudos_gestacao são preservados', () {
      const naoEstudava = EducacaoModel(
        escolaridade: 'medio_completo',
        situacaoEstudosGestacao: 'nao_estudava',
      );
      const naoInterrompeu = EducacaoModel(
        escolaridade: 'medio_completo',
        situacaoEstudosGestacao: 'nao_interrompeu',
      );
      const interrompeu = EducacaoModel(
        escolaridade: 'medio_completo',
        situacaoEstudosGestacao: 'interrompeu',
      );

      expect(naoEstudava.toMap()['situacao_estudos_gestacao'], 'nao_estudava');
      expect(naoInterrompeu.toMap()['situacao_estudos_gestacao'], 'nao_interrompeu');
      expect(interrompeu.toMap()['situacao_estudos_gestacao'], 'interrompeu');
    });

    test('fromMap/toMap preserva a múltipla escolha e a situação (round-trip)', () {
      const model = EducacaoModel(
        estuda: false,
        escolaridade: 'superior_completo',
        situacaoEstudosGestacao: 'interrompeu',
        dificuldadesEducacao: ['gravidez', 'trabalho', 'outro'],
        entendeOrientacoes: false,
        fezCursoQualificacaoProfissional: false,
      );

      final restored = EducacaoModel.fromMap(model.toMap());

      expect(restored, model);
      expect(restored.dificuldadesEducacao, ['gravidez', 'trabalho', 'outro']);
    });

    test('fromMap trata campos ausentes como null/vazio', () {
      final model = EducacaoModel.fromMap(const {});

      expect(model.escolaridade, isNull);
      expect(model.dificuldadesEducacao, isEmpty);
      expect(model.estuda, isNull);
      expect(model.situacaoEstudosGestacao, isNull);
      expect(model.entendeOrientacoes, isNull);
      expect(model.fezCursoQualificacaoProfissional, isNull);
    });

    test('empty() começa com tudo nulo e sem dificuldades', () {
      final model = EducacaoModel.empty();

      expect(model.escolaridade, isNull);
      expect(model.dificuldadesEducacao, isEmpty);
      expect(model.estuda, isNull);
      expect(model.situacaoEstudosGestacao, isNull);
      expect(model.entendeOrientacoes, isNull);
      expect(model.fezCursoQualificacaoProfissional, isNull);
    });

    test('true preserva true, false preserva false, null preserva null (round-trip)', () {
      const model = EducacaoModel(
        estuda: true,
        escolaridade: 'medio_completo',
        situacaoEstudosGestacao: 'nao_estudava',
        entendeOrientacoes: null,
        fezCursoQualificacaoProfissional: null,
      );

      final restored = EducacaoModel.fromMap(model.toMap());

      expect(restored.estuda, isTrue);
      expect(restored.entendeOrientacoes, isNull);
      expect(restored.fezCursoQualificacaoProfissional, isNull);
      expect(restored, model);
    });

    test('escolaridade superior é discriminada em incompleto/completo', () {
      const incompleto = EducacaoModel(
        estuda: false,
        escolaridade: 'superior_incompleto',
        situacaoEstudosGestacao: 'nao_interrompeu',
        entendeOrientacoes: false,
        fezCursoQualificacaoProfissional: false,
      );
      const completo = EducacaoModel(
        estuda: false,
        escolaridade: 'superior_completo',
        situacaoEstudosGestacao: 'nao_interrompeu',
        entendeOrientacoes: false,
        fezCursoQualificacaoProfissional: false,
      );

      expect(incompleto.toMap()['escolaridade'], 'superior_incompleto');
      expect(completo.toMap()['escolaridade'], 'superior_completo');
      expect(EducacaoModel.fromMap(incompleto.toMap()), incompleto);
      expect(EducacaoModel.fromMap(completo.toMap()), completo);
    });
  });
}
