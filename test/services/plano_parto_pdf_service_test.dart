import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/services/pdf/plano_parto_pdf_service.dart';
import 'package:meu_bebe/app/model/gestacao/gestacao_model.dart';
import 'package:meu_bebe/app/model/gestante/gestante_model.dart';
import 'package:meu_bebe/app/model/historico_obstetrico/historico_obstetrico_model.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanoPartoPdfService', () {
    const service = PlanoPartoPdfService();

    test('gera documento PDF válido com cabeçalho PDF padrão com dados completos', () async {
      final gestante = GestanteModel(
        id: 'gestante-123',
        nome: 'Maria da Silva Sauro',
        nomeSocial: 'Maria Silva',
        cns: '700000000000001',
        dataNascimento: '1995-05-20',
        cpf: '12345678901',
      );

      final gestacao = GestacaoModel(
        id: 'gestacao-456',
        dataUltimaMenstruacao: '2026-01-10',
        localPreNatal: 'UBS Central',
        profissionalPreNatal: 'Dra. Ana',
        contatoLocalPreNatal: '92999998888',
      );

      final historico = HistoricoObstetricoModel(
        id: 'hist-789',
        pregnancyNumber: 2,
        givenBirthNumber: 1,
        abortionsNumber: 1,
      );

      const plano = PlanoPartoModel(
        id: 'plano-001',
        acompanhante: 'sim',
        rasparPelosIntimos: 'nao',
        lavagemIntestinal: 'nao',
        ambientePoucaLuz: 'sim',
        ouvirMusica: 'sim',
        beberLiquidos: 'sim',
        registrarFotosVideos: 'sim',
        viaParto: 'vaginal',
        anestesia: 'nao',
        corteVaginal: 'nao',
        posicaoPreferida: 'agachada',
        outraPosicao: null,
        quemCortaCordao: 'acompanhante',
        coletaCelulasTronco: false,
        contatoPeleAPele: 'sim',
        amamentarPrimeiraHora: 'sim',
        restricoesAmamentacao: false,
        primeiroBanho: 'acompanhante',
        querAlivioDor: 'sim',
        massagem: true,
        exerciciosBola: true,
        exerciciosRespiracao: true,
        banhoChuveiro: true,
        banhoBanheira: false,
        acupuntura: false,
        acupressao: false,
        outroMetodo: false,
        observacoes: 'Gostaria de iluminação suave e respeito às escolhas informadas.',
      );

      final bytes = await service.generatePlanoPartoPdf(
        gestante: gestante,
        gestacao: gestacao,
        historico: historico,
        plano: plano,
        firstUltrasound: '2026-02-28',
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);

      // Assinatura padrão do PDF: "%PDF-"
      final magicHeader = String.fromCharCodes(bytes.take(5));
      expect(magicHeader, equals('%PDF-'));
    });

    test('gera documento PDF válido mesmo com campos nulos (graceful null fallback)', () async {
      final bytes = await service.generatePlanoPartoPdf(
        gestante: null,
        gestacao: null,
        historico: null,
        plano: null,
        firstUltrasound: null,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);

      final magicHeader = String.fromCharCodes(bytes.take(5));
      expect(magicHeader, equals('%PDF-'));
    });
  });
}
