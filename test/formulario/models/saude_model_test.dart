import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/saude/saude_model.dart';

void main() {
  group('SaudeModel', () {
    test('toMap serializa dificuldades_saude como lista de códigos canônicos', () {
      const model = SaudeModel(
        faltouConsulta: false,
        examesPreNatalCompletos: false,
        vacinasEmDia: false,
        dificuldadesSaude: ['falta_transporte', 'demora_atendimento'],
      );

      final map = model.toMap();

      expect(map['dificuldades_saude'], ['falta_transporte', 'demora_atendimento']);
      expect(map['dificuldades_saude'], isNot(contains('Falta de transporte')));
    });

    test('fromMap/toMap preserva a lista de dificuldades (round-trip)', () {
      const model = SaudeModel(
        distanciaUBS: 'distante',
        faltouConsulta: true,
        acessoUBS: 'a_pe',
        cadastradaUBS: true,
        servicosPreNatal: ['consulta_medica'],
        examesPreNatalCompletos: true,
        vacinasEmDia: false,
        avaliacaoPreNatal: 'bom',
        dificuldadesSaude: ['horario_incompativel', 'outro'],
      );

      final restored = SaudeModel.fromMap(model.toMap());

      expect(restored, model);
    });

    test('fromMap trata ausência de dificuldades_saude como lista vazia', () {
      final model = SaudeModel.fromMap(const {
        'faltou_consulta': false,
        'exames_pre_natal_completos': false,
        'vacinas_em_dia': false,
      });

      expect(model.dificuldadesSaude, isEmpty);
    });

    test('empty() começa sem dificuldades e com booleanos nulos', () {
      final model = SaudeModel.empty();

      expect(model.faltouConsulta, isNull);
      expect(model.examesPreNatalCompletos, isNull);
      expect(model.vacinasEmDia, isNull);
      expect(model.dificuldadesSaude, isEmpty);
    });

    test('faltou_consulta, exames e vacinas preservam true, false e null', () {
      const model = SaudeModel(faltouConsulta: true, examesPreNatalCompletos: false, vacinasEmDia: null);

      final restored = SaudeModel.fromMap(model.toMap());

      expect(restored.faltouConsulta, isTrue);
      expect(restored.examesPreNatalCompletos, isFalse);
      expect(restored.vacinasEmDia, isNull);
    });
  });
}
