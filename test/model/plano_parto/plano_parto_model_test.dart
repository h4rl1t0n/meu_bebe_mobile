import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_enums.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';

Map<String, dynamic> _fullBody({String id = 'pp-1'}) => {
  'id': id,
  // Expectativas
  'acompanhante': 'sim',
  'raspar_pelos_intimos': 'nao',
  'lavagem_intestinal': 'nao_sei',
  'ambiente_pouca_luz': 'sim',
  'ouvir_musica': 'nao',
  'beber_liquidos': 'sim',
  'registrar_fotos_videos': 'nao_sei',
  // Momento do parto
  'via_parto': 'vaginal',
  'anestesia': 'sim',
  'corte_vaginal': 'nao',
  'posicao_preferida': 'sentada',
  'outra_posicao': null,
  // Nascimento
  'quem_corta_cordao': 'acompanhante',
  'coleta_celulas_tronco': true,
  'contato_pele_a_pele': 'sim',
  'amamentar_primeira_hora': 'sim',
  'restricoes_amamentacao': false,
  'primeiro_banho': 'profissional',
  // Alívio da dor
  'quer_alivio_dor': 'sim',
  'massagem': true,
  'exercicios_bola': true,
  'exercicios_respiracao': false,
  'banho_chuveiro': true,
  'banho_banheira': false,
  'acupuntura': false,
  'acupressao': true,
  'outro_metodo': false,
  // Observações
  'observacoes': 'Prefiro luz baixa',
};

void main() {
  group('PlanoPartoModel.tryParse', () {
    test('payload completo → parseia os 28 campos', () {
      final plano = PlanoPartoModel.tryParse(_fullBody());

      expect(plano, isNotNull);
      expect(plano!.id, 'pp-1');
      expect(plano.acompanhante, 'sim');
      expect(plano.rasparPelosIntimos, 'nao');
      expect(plano.lavagemIntestinal, 'nao_sei');
      expect(plano.ambientePoucaLuz, 'sim');
      expect(plano.ouvirMusica, 'nao');
      expect(plano.beberLiquidos, 'sim');
      expect(plano.registrarFotosVideos, 'nao_sei');
      expect(plano.viaParto, 'vaginal');
      expect(plano.anestesia, 'sim');
      expect(plano.corteVaginal, 'nao');
      expect(plano.posicaoPreferida, 'sentada');
      expect(plano.outraPosicao, isNull);
      expect(plano.quemCortaCordao, 'acompanhante');
      expect(plano.coletaCelulasTronco, isTrue);
      expect(plano.contatoPeleAPele, 'sim');
      expect(plano.amamentarPrimeiraHora, 'sim');
      expect(plano.restricoesAmamentacao, isFalse);
      expect(plano.primeiroBanho, 'profissional');
      expect(plano.querAlivioDor, 'sim');
      expect(plano.massagem, isTrue);
      expect(plano.exerciciosBola, isTrue);
      expect(plano.exerciciosRespiracao, isFalse);
      expect(plano.banhoChuveiro, isTrue);
      expect(plano.banhoBanheira, isFalse);
      expect(plano.acupuntura, isFalse);
      expect(plano.acupressao, isTrue);
      expect(plano.outroMetodo, isFalse);
      expect(plano.observacoes, 'Prefiro luz baixa');
    });

    test('campos ausentes → caem no canônico "não informado" (nunca inventa)', () {
      final plano = PlanoPartoModel.tryParse({'id': 'pp-x'})!;

      expect(plano.acompanhante, 'nao_sei');
      expect(plano.viaParto, 'nao_sei');
      expect(plano.quemCortaCordao, 'nao_sei');
      expect(plano.posicaoPreferida, isNull);
      expect(plano.coletaCelulasTronco, isFalse);
      expect(plano.observacoes, '');
    });

    test('valor clínico desconhecido → nao_sei (não vira "não")', () {
      final plano = PlanoPartoModel.tryParse({
        'acompanhante': 'x-inventado',
        'via_parto': 42,
        'quem_corta_cordao': 'x',
      })!;

      expect(plano.acompanhante, 'nao_sei');
      expect(plano.viaParto, 'nao_sei');
      expect(plano.quemCortaCordao, 'nao_sei');
    });

    test('não-map → null', () {
      expect(PlanoPartoModel.tryParse('não é um objeto'), isNull);
      expect(PlanoPartoModel.tryParse(null), isNull);
    });
  });

  group('PlanoPartoModel.empty', () {
    test('nasce todo "não informado"', () {
      final p = PlanoPartoModel.empty();
      expect(p.id, isNull);
      expect(p.acompanhante, 'nao_sei');
      expect(p.viaParto, 'nao_sei');
      expect(p.posicaoPreferida, isNull);
      expect(p.outraPosicao, isNull);
      expect(p.coletaCelulasTronco, isFalse);
      expect(p.restricoesAmamentacao, isFalse);
      expect(p.observacoes, '');
    });
  });

  group('PlanoPartoModel.toWriteJson', () {
    test('escreve 28 chaves estáveis e nunca id/gestacao_id/timestamps', () {
      final json = PlanoPartoModel.tryParse(_fullBody())!.toWriteJson();

      expect(json.length, 28);
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('gestacao_id'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
      expect(json['acompanhante'], 'sim');
      expect(json['raspar_pelos_intimos'], 'nao');
      expect(json['via_parto'], 'vaginal');
      expect(json['coleta_celulas_tronco'], true);
      expect(json['primeiro_banho'], 'profissional');
      expect(json['massagem'], true);
      expect(json['observacoes'], 'Prefiro luz baixa');
    });

    test('outra_posicao vazia → null', () {
      final json = PlanoPartoModel.empty()
          .copyWith(outraPosicao: '   ')
          .toWriteJson();
      expect(json['outra_posicao'], isNull);
    });

    test('observações vazias são permitidas', () {
      final json = PlanoPartoModel.empty().toWriteJson();
      expect(json['observacoes'], '');
    });
  });

  group('PlanoPartoModel.copyWith', () {
    test('preserva as demais seções ao editar uma única seção', () {
      final full = PlanoPartoModel.tryParse(_fullBody())!;
      final updated = full.copyWith(acompanhante: 'nao');

      expect(updated.acompanhante, 'nao');
      // As outras 27 continuam intactas.
      expect(updated.rasparPelosIntimos, 'nao');
      expect(updated.viaParto, 'vaginal');
      expect(updated.posicaoPreferida, 'sentada');
      expect(updated.quemCortaCordao, 'acompanhante');
      expect(updated.querAlivioDor, 'sim');
      expect(updated.massagem, isTrue);
      expect(updated.observacoes, 'Prefiro luz baixa');
      expect(updated.id, 'pp-1');
    });

    test('posicaoPreferida pode ser limpa para null (sentinel)', () {
      final full = PlanoPartoModel.tryParse(_fullBody())!;
      final updated = full.copyWith(posicaoPreferida: null);
      expect(updated.posicaoPreferida, isNull);
    });

    test('outraPosicao pode ser limpa para null (sentinel)', () {
      final full = PlanoPartoModel.tryParse(_fullBody())!;
      final updated = full.copyWith(outraPosicao: null);
      expect(updated.outraPosicao, isNull);
    });

    test('id preservado quando não sobrescrito', () {
      final full = PlanoPartoModel.tryParse(_fullBody())!;
      final updated = full.copyWith(beberLiquidos: 'sim');
      expect(updated.id, 'pp-1');
    });
  });

  group('PlanoPartoModel igualdade', () {
    test('== e hashCode refletem os 28 campos', () {
      final a = PlanoPartoModel.tryParse(_fullBody())!;
      final b = PlanoPartoModel.tryParse(_fullBody())!;
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final c = a.copyWith(acompanhante: 'nao');
      expect(a, isNot(equals(c)));
    });
  });

  group('enums estáveis (nunca ordinal)', () {
    test('TriState.fromValue', () {
      expect(TriState.fromValue('sim'), TriState.sim);
      expect(TriState.fromValue('nao'), TriState.nao);
      expect(TriState.fromValue('nao_sei'), TriState.naoSei);
      expect(TriState.fromValue('garbage'), TriState.naoSei);
      expect(TriState.fromValue(null), TriState.naoSei);
      expect(TriState.sim.value, 'sim');
      expect(TriState.nao.label, 'Não');
    });

    test('ViaParto.fromValue', () {
      expect(ViaParto.fromValue('vaginal'), ViaParto.vaginal);
      expect(ViaParto.fromValue('cesarea'), ViaParto.cesarea);
      expect(ViaParto.fromValue('nao_sei'), ViaParto.naoSei);
      expect(ViaParto.fromValue('garbage'), ViaParto.naoSei);
    });

    test('ActorChoice.fromValue', () {
      expect(ActorChoice.fromValue('profissional'), ActorChoice.profissional);
      expect(ActorChoice.fromValue('acompanhante'), ActorChoice.acompanhante);
      expect(ActorChoice.fromValue('eu'), ActorChoice.eu);
      expect(ActorChoice.fromValue('garbage'), ActorChoice.naoSei);
    });

    test('PosicaoParto.fromValue retorna null para ausente/desconhecido', () {
      expect(PosicaoParto.fromValue('deitada'), PosicaoParto.deitada);
      expect(PosicaoParto.fromValue('de_lado'), PosicaoParto.deLado);
      expect(PosicaoParto.fromValue('outra'), PosicaoParto.outra);
      expect(PosicaoParto.fromValue('garbage'), isNull);
      expect(PosicaoParto.fromValue(null), isNull);
    });
  });
}
