import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/habitacao_options.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/habitacao/habitacao_controller.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/habitacao/habitacao_validator.dart';

void main() {
  group('HabitacaoController', () {
    test('toggleMelhoriaMoradia codifica como lista de códigos canônicos', () {
      final controller = HabitacaoController();
      controller.toggleMelhoriaMoradia(MelhoriaMoradia.melhorarBanheiro);
      controller.toggleMelhoriaMoradia(MelhoriaMoradia.melhorarVentilacao);

      expect(controller.buildHabitacaoData().melhoriasDesejadas, ['melhorar_banheiro', 'melhorar_ventilacao']);
    });

    test('sem_melhorias é mutuamente exclusiva: selecioná-la limpa as demais', () {
      final controller = HabitacaoController();
      controller.toggleMelhoriaMoradia(MelhoriaMoradia.melhorarBanheiro);
      controller.toggleMelhoriaMoradia(MelhoriaMoradia.ampliacaoEspaco);

      controller.toggleMelhoriaMoradia(MelhoriaMoradia.semMelhorias);

      expect(controller.buildHabitacaoData().melhoriasDesejadas, ['sem_melhorias']);
    });

    test('selecionar outra melhoria remove sem_melhorias', () {
      final controller = HabitacaoController();
      controller.toggleMelhoriaMoradia(MelhoriaMoradia.semMelhorias);

      controller.toggleMelhoriaMoradia(MelhoriaMoradia.reformaEstrutura);

      final codes = controller.buildHabitacaoData().melhoriasDesejadas;
      expect(codes, contains('reforma_estrutura'));
      expect(codes, isNot(contains('sem_melhorias')));
    });

    test('desmarcar sem_melhorias esvazia a lista (permite deseleção)', () {
      final controller = HabitacaoController();
      controller.toggleMelhoriaMoradia(MelhoriaMoradia.semMelhorias);
      expect(controller.buildHabitacaoData().melhoriasDesejadas, ['sem_melhorias']);

      controller.toggleMelhoriaMoradia(MelhoriaMoradia.semMelhorias);
      expect(controller.buildHabitacaoData().melhoriasDesejadas, isEmpty);
    });

    test('buildHabitacaoData serializa categorias por código (nunca label)', () {
      final controller = HabitacaoController();
      controller.setTipoMoradia(TipoMoradia.casa);
      controller.setMaterialMoradia(MaterialMoradia.alvenaria);
      controller.setSegurancaResidencia(SegurancaResidencia.segura);

      final data = controller.buildHabitacaoData();
      expect(data.tipoMoradia, 'casa');
      expect(data.materialMoradia, 'alvenaria');
      expect(data.segurancaResidencia, 'segura');
    });

    test('todos os obrigatórios preenchidos → válido', () {
      final controller = HabitacaoController();
      controller.setTipoMoradia(TipoMoradia.casa);
      controller.setMaterialMoradia(MaterialMoradia.alvenaria);
      controller.setNumeroPessoas(3);
      controller.setNumeroComodos(4);
      controller.setNumeroDormitorios(2);
      controller.setSegurancaResidencia(SegurancaResidencia.segura);

      expect(controller.isValid, isTrue);
    });

    test('tipo_moradia ausente → inválido', () {
      final controller = HabitacaoController();
      controller.setMaterialMoradia(MaterialMoradia.alvenaria);
      controller.setNumeroPessoas(3);
      controller.setNumeroComodos(4);
      controller.setNumeroDormitorios(2);
      controller.setSegurancaResidencia(SegurancaResidencia.segura);

      expect(controller.isValid, isFalse);
    });

    test('material_moradia ausente → inválido', () {
      final controller = HabitacaoController();
      controller.setTipoMoradia(TipoMoradia.casa);
      controller.setNumeroPessoas(3);
      controller.setNumeroComodos(4);
      controller.setNumeroDormitorios(2);
      controller.setSegurancaResidencia(SegurancaResidencia.segura);

      expect(controller.isValid, isFalse);
    });

    test('numero_pessoas 0 (não respondido) → inválido', () {
      final controller = HabitacaoController();
      controller.setTipoMoradia(TipoMoradia.casa);
      controller.setMaterialMoradia(MaterialMoradia.alvenaria);
      controller.setNumeroComodos(4);
      controller.setNumeroDormitorios(2);
      controller.setSegurancaResidencia(SegurancaResidencia.segura);

      expect(controller.isValid, isFalse);
    });

    test('numero_comodos 0 (não respondido) → inválido', () {
      final controller = HabitacaoController();
      controller.setTipoMoradia(TipoMoradia.casa);
      controller.setMaterialMoradia(MaterialMoradia.alvenaria);
      controller.setNumeroPessoas(3);
      controller.setNumeroDormitorios(2);
      controller.setSegurancaResidencia(SegurancaResidencia.segura);

      expect(controller.isValid, isFalse);
    });

    test('numero_dormitorios 0 (não respondido) → inválido', () {
      final controller = HabitacaoController();
      controller.setTipoMoradia(TipoMoradia.casa);
      controller.setMaterialMoradia(MaterialMoradia.alvenaria);
      controller.setNumeroPessoas(3);
      controller.setNumeroComodos(4);
      controller.setSegurancaResidencia(SegurancaResidencia.segura);

      expect(controller.isValid, isFalse);
    });

    test('seguranca_residencia ausente → inválido', () {
      final controller = HabitacaoController();
      controller.setTipoMoradia(TipoMoradia.casa);
      controller.setMaterialMoradia(MaterialMoradia.alvenaria);
      controller.setNumeroPessoas(3);
      controller.setNumeroComodos(4);
      controller.setNumeroDormitorios(2);

      expect(controller.isValid, isFalse);
    });

    test('comodos = 4, dormitorios = 2 → válido', () {
      final controller = HabitacaoController();
      controller.setTipoMoradia(TipoMoradia.casa);
      controller.setMaterialMoradia(MaterialMoradia.alvenaria);
      controller.setNumeroPessoas(3);
      controller.setNumeroComodos(4);
      controller.setNumeroDormitorios(2);
      controller.setSegurancaResidencia(SegurancaResidencia.segura);

      expect(controller.isValid, isTrue);
    });

    test('comodos = 2, dormitorios = 2 → válido', () {
      final controller = HabitacaoController();
      controller.setTipoMoradia(TipoMoradia.casa);
      controller.setMaterialMoradia(MaterialMoradia.alvenaria);
      controller.setNumeroPessoas(3);
      controller.setNumeroComodos(2);
      controller.setNumeroDormitorios(2);
      controller.setSegurancaResidencia(SegurancaResidencia.segura);

      expect(controller.isValid, isTrue);
    });

    test('comodos = 2, dormitorios = 3 → inválido (dormitórios > cômodos)', () {
      final controller = HabitacaoController();
      controller.setTipoMoradia(TipoMoradia.casa);
      controller.setMaterialMoradia(MaterialMoradia.alvenaria);
      controller.setNumeroPessoas(3);
      controller.setNumeroComodos(2);
      controller.setNumeroDormitorios(3);
      controller.setSegurancaResidencia(SegurancaResidencia.segura);

      expect(controller.isValid, isFalse);
    });

    test('validator numeroDormitorios rejeita dormitórios > cômodos na UI', () {
      expect(HabitacaoValidator.numeroDormitorios('3', numeroComodos: 2), isNotNull);
      expect(HabitacaoValidator.numeroDormitorios('2', numeroComodos: 2), isNull);
      expect(HabitacaoValidator.numeroDormitorios('1', numeroComodos: 1), isNull);
    });
  });
}
