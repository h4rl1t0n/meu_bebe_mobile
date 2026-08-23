import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/formulario/models/saneamento/saneamento_model.dart';

void main() {
  group('SaneamentoModel', () {
    test('toMap serializa cuidados_vetores como lista de códigos canônicos', () {
      const model = SaneamentoModel(
        interrupcoesAgua: false,
        preocupacaoAgua: false,
        cuidadosVetores: ['usa_repelente', 'elimina_agua_parada'],
      );

      final map = model.toMap();

      expect(map['cuidados_vetores'], ['usa_repelente', 'elimina_agua_parada']);
      expect(map['cuidados_vetores'], isNot(contains('Usa repelente')));
    });

    test('toMap separa regularidade da coleta e destinação sem coleta (sem coleta_lixo ambíguo)', () {
      const model = SaneamentoModel(
        interrupcoesAgua: false,
        preocupacaoAgua: false,
        frequenciaColetaLixo: 'irregular',
        destinoLixoSemColeta: 'queima',
      );

      final map = model.toMap();

      expect(map['frequencia_coleta_lixo'], 'irregular');
      expect(map['destino_lixo_sem_coleta'], 'queima');
      expect(map.containsKey('coleta_lixo'), isFalse);
    });

    test('fromMap/toMap preserva os campos (round-trip)', () {
      const model = SaneamentoModel(
        fonteAgua: 'rede_publica',
        interrupcoesAgua: true,
        esgotamentoSanitario: 'fossa_septica',
        frequenciaColetaLixo: 'nao_possui',
        destinoLixoSemColeta: 'terreno_baldio',
        preocupacaoAgua: false,
        cuidadosVetores: ['mantem_reservatorios_tampados', 'outro'],
      );

      final restored = SaneamentoModel.fromMap(model.toMap());

      expect(restored, model);
    });

    test('aguarda_proxima_coleta é serializada como código canônico (round-trip)', () {
      const model = SaneamentoModel(
        interrupcoesAgua: false,
        preocupacaoAgua: false,
        frequenciaColetaLixo: 'irregular',
        destinoLixoSemColeta: 'aguarda_proxima_coleta',
      );

      final map = model.toMap();
      expect(map['destino_lixo_sem_coleta'], 'aguarda_proxima_coleta');
      expect(map['destino_lixo_sem_coleta'], isNot(contains('Armazena')));

      expect(SaneamentoModel.fromMap(map), model);
    });

    test('destino_lixo_sem_coleta ausente é tratado como null (não aplicável/não respondido)', () {
      final model = SaneamentoModel.fromMap(const {
        'interrupcoes_agua': false,
        'problema_saude_agua': false,
        'frequencia_coleta_lixo': 'regular',
      });

      expect(model.destinoLixoSemColeta, isNull);
      expect(model.frequenciaColetaLixo, 'regular');
    });

    test('fromMap trata ausência de cuidados_vetores como lista vazia', () {
      final model = SaneamentoModel.fromMap(const {
        'interrupcoes_agua': false,
        'problema_saude_agua': false,
      });

      expect(model.cuidadosVetores, isEmpty);
    });

    test('empty() começa sem categorias e com booleanos nulos', () {
      final model = SaneamentoModel.empty();

      expect(model.interrupcoesAgua, isNull);
      expect(model.preocupacaoAgua, isNull);
      expect(model.cuidadosVetores, isEmpty);
      expect(model.frequenciaColetaLixo, isNull);
      expect(model.destinoLixoSemColeta, isNull);
    });

    test('interrupcoes_agua e problema_saude_agua preservam true, false e null', () {
      const comProblema = SaneamentoModel(interrupcoesAgua: true, preocupacaoAgua: false);
      const semProblema = SaneamentoModel(interrupcoesAgua: false, preocupacaoAgua: true);
      const naoRespondido = SaneamentoModel();

      expect(SaneamentoModel.fromMap(comProblema.toMap()).interrupcoesAgua, isTrue);
      expect(SaneamentoModel.fromMap(comProblema.toMap()).preocupacaoAgua, isFalse);
      expect(SaneamentoModel.fromMap(semProblema.toMap()).interrupcoesAgua, isFalse);
      expect(SaneamentoModel.fromMap(semProblema.toMap()).preocupacaoAgua, isTrue);
      expect(SaneamentoModel.fromMap(naoRespondido.toMap()).interrupcoesAgua, isNull);
      expect(SaneamentoModel.fromMap(naoRespondido.toMap()).preocupacaoAgua, isNull);
    });
  });
}
