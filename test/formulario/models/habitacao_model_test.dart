import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/habitacao/habitacao_model.dart';

void main() {
  group('HabitacaoModel', () {
    test('toMap serializa melhorias_desejadas como lista de códigos canônicos (não texto livre)', () {
      const model = HabitacaoModel(
        numeroPessoas: 3,
        numeroComodos: 4,
        numeroDormitorios: 2,
        facilAcessoSaude: false,
        melhoriasDesejadas: ['melhorar_banheiro', 'melhorar_ventilacao'],
      );

      final map = model.toMap();

      expect(map['melhorias_desejadas'], ['melhorar_banheiro', 'melhorar_ventilacao']);
      expect(map['melhorias_desejadas'], isNot(contains('Melhorar o banheiro')));
      expect(map['melhorias_desejadas'], isNot(isA<String>()));
    });

    test('toMap separa tipo_moradia (tipo) de material_moradia (material)', () {
      const model = HabitacaoModel(
        tipoMoradia: 'casa',
        materialMoradia: 'alvenaria',
        numeroPessoas: 3,
        numeroComodos: 4,
        numeroDormitorios: 2,
        facilAcessoSaude: false,
      );

      final map = model.toMap();

      expect(map['tipo_moradia'], 'casa');
      expect(map['material_moradia'], 'alvenaria');
    });

    test('toMap inclui numero_dormitorios (distinto de numero_comodos)', () {
      const model = HabitacaoModel(
        numeroPessoas: 3,
        numeroComodos: 4,
        numeroDormitorios: 2,
        facilAcessoSaude: false,
      );

      final map = model.toMap();

      expect(map['numero_comodos'], 4);
      expect(map['numero_dormitorios'], 2);
    });

    test('fromMap/toMap preserva os campos (round-trip)', () {
      const model = HabitacaoModel(
        tipoMoradia: 'apartamento',
        materialMoradia: 'alvenaria',
        numeroPessoas: 2,
        numeroComodos: 3,
        numeroDormitorios: 1,
        itensResidencia: ['agua_encanada', 'banheiro_interno'],
        segurancaResidencia: 'segura',
        melhoriasDesejadas: ['reforma_estrutura', 'outro'],
        facilAcessoSaude: true,
      );

      final restored = HabitacaoModel.fromMap(model.toMap());

      expect(restored, model);
    });

    test('melhorias_desejadas ausente é tratado como lista vazia', () {
      final model = HabitacaoModel.fromMap(const {
        'numero_pessoas': 3,
        'numero_comodos': 4,
        'numero_dormitorios': 2,
        'facil_acesso_saude': false,
      });

      expect(model.melhoriasDesejadas, isEmpty);
      expect(model.materialMoradia, isNull);
    });

    test('empty() começa com números 0, listas vazias e booleanos falsos', () {
      final model = HabitacaoModel.empty();

      expect(model.numeroPessoas, 0);
      expect(model.numeroComodos, 0);
      expect(model.numeroDormitorios, 0);
      expect(model.itensResidencia, isEmpty);
      expect(model.melhoriasDesejadas, isEmpty);
      expect(model.tipoMoradia, isNull);
      expect(model.materialMoradia, isNull);
      expect(model.segurancaResidencia, isNull);
      expect(model.facilAcessoSaude, isFalse);
    });
  });
}
