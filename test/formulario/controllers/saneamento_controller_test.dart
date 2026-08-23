import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/catalog/saneamento_options.dart';
import 'package:meu_bebe/app/modules/formulario/submodules/saneamento/saneamento_controller.dart';

void main() {
  group('SaneamentoController', () {
    test('toggleCuidadoVetor codifica como lista de códigos canônicos no buildSaneamentoData', () {
      final controller = SaneamentoController();
      controller.toggleCuidadoVetor(CuidadoVetor.usaRepelente);
      controller.toggleCuidadoVetor(CuidadoVetor.eliminaAguaParada);

      expect(controller.buildSaneamentoData().cuidadosVetores, ['usa_repelente', 'elimina_agua_parada']);
    });

    test('sem_cuidados é mutuamente exclusiva: selecioná-la limpa as demais', () {
      final controller = SaneamentoController();
      controller.toggleCuidadoVetor(CuidadoVetor.usaRepelente);
      controller.toggleCuidadoVetor(CuidadoVetor.eliminaAguaParada);

      controller.toggleCuidadoVetor(CuidadoVetor.semCuidados);

      expect(controller.buildSaneamentoData().cuidadosVetores, ['sem_cuidados']);
    });

    test('selecionar outro cuidado remove sem_cuidados', () {
      final controller = SaneamentoController();
      controller.toggleCuidadoVetor(CuidadoVetor.semCuidados);

      controller.toggleCuidadoVetor(CuidadoVetor.usaInseticida);

      final codes = controller.buildSaneamentoData().cuidadosVetores;
      expect(codes, contains('usa_inseticida'));
      expect(codes, isNot(contains('sem_cuidados')));
    });

    test('desmarcar sem_cuidados esvazia a lista (permite deseleção)', () {
      final controller = SaneamentoController();
      controller.toggleCuidadoVetor(CuidadoVetor.semCuidados);
      expect(controller.buildSaneamentoData().cuidadosVetores, ['sem_cuidados']);

      controller.toggleCuidadoVetor(CuidadoVetor.semCuidados);
      expect(controller.buildSaneamentoData().cuidadosVetores, isEmpty);
    });

    test('buildSaneamentoData serializa categorias por código (nunca label)', () {
      final controller = SaneamentoController();
      controller.setFonteAgua(FonteAgua.redePublica);
      controller.setEsgotamentoSanitario(EsgotamentoSanitario.fossaSeptica);
      controller.setFrequenciaColetaLixo(FrequenciaColetaLixo.irregular);
      controller.setDestinoLixoSemColeta(DestinoLixoSemColeta.queima);

      final data = controller.buildSaneamentoData();
      expect(data.fonteAgua, 'rede_publica');
      expect(data.esgotamentoSanitario, 'fossa_septica');
      expect(data.frequenciaColetaLixo, 'irregular');
      expect(data.destinoLixoSemColeta, 'queima');
    });

    test('regular → destino null → válido', () {
      final controller = SaneamentoController();
      controller.setFonteAgua(FonteAgua.redePublica);
      controller.setEsgotamentoSanitario(EsgotamentoSanitario.fossaSeptica);
      controller.setFrequenciaColetaLixo(FrequenciaColetaLixo.regular);

      expect(controller.isValid, isTrue);
      expect(controller.buildSaneamentoData().destinoLixoSemColeta, isNull);
    });

    test('irregular + destino null → inválido', () {
      final controller = SaneamentoController();
      controller.setFonteAgua(FonteAgua.redePublica);
      controller.setEsgotamentoSanitario(EsgotamentoSanitario.fossaSeptica);
      controller.setFrequenciaColetaLixo(FrequenciaColetaLixo.irregular);

      expect(controller.isValid, isFalse);
    });

    test('irregular + aguarda_proxima_coleta → válido', () {
      final controller = SaneamentoController();
      controller.setFonteAgua(FonteAgua.redePublica);
      controller.setEsgotamentoSanitario(EsgotamentoSanitario.fossaSeptica);
      controller.setFrequenciaColetaLixo(FrequenciaColetaLixo.irregular);
      controller.setDestinoLixoSemColeta(DestinoLixoSemColeta.aguardaProximaColeta);

      expect(controller.isValid, isTrue);
      expect(controller.buildSaneamentoData().destinoLixoSemColeta, 'aguarda_proxima_coleta');
    });

    test('irregular + queima → válido', () {
      final controller = SaneamentoController();
      controller.setFonteAgua(FonteAgua.redePublica);
      controller.setEsgotamentoSanitario(EsgotamentoSanitario.fossaSeptica);
      controller.setFrequenciaColetaLixo(FrequenciaColetaLixo.irregular);
      controller.setDestinoLixoSemColeta(DestinoLixoSemColeta.queima);

      expect(controller.isValid, isTrue);
      expect(controller.buildSaneamentoData().destinoLixoSemColeta, 'queima');
    });

    test('nao_possui + destino válido → válido', () {
      final controller = SaneamentoController();
      controller.setFonteAgua(FonteAgua.redePublica);
      controller.setEsgotamentoSanitario(EsgotamentoSanitario.fossaSeptica);
      controller.setFrequenciaColetaLixo(FrequenciaColetaLixo.naoPossui);
      controller.setDestinoLixoSemColeta(DestinoLixoSemColeta.terrenoBaldio);

      expect(controller.isValid, isTrue);
      expect(controller.buildSaneamentoData().destinoLixoSemColeta, 'terreno_baldio');
    });

    test('nao_possui + destino null → inválido', () {
      final controller = SaneamentoController();
      controller.setFonteAgua(FonteAgua.redePublica);
      controller.setEsgotamentoSanitario(EsgotamentoSanitario.fossaSeptica);
      controller.setFrequenciaColetaLixo(FrequenciaColetaLixo.naoPossui);

      expect(controller.isValid, isFalse);
    });

    test('aguarda_proxima_coleta é proibida para nao_possui (é limpa na transição)', () {
      final controller = SaneamentoController();
      controller.setFrequenciaColetaLixo(FrequenciaColetaLixo.irregular);
      controller.setDestinoLixoSemColeta(DestinoLixoSemColeta.aguardaProximaColeta);
      expect(controller.buildSaneamentoData().destinoLixoSemColeta, 'aguarda_proxima_coleta');

      controller.setFrequenciaColetaLixo(FrequenciaColetaLixo.naoPossui);

      expect(controller.buildSaneamentoData().destinoLixoSemColeta, isNull);
    });
  });
}
