import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../model/gestacao/gestacao_model.dart';
import '../../../model/gestante/gestante_model.dart';
import '../../../model/historico_obstetrico/historico_obstetrico_model.dart';
import '../../../model/plano_parto/plano_parto_enums.dart';
import '../../../model/plano_parto/plano_parto_model.dart';

/// Serviço responsável por gerar e exportar o PDF do Plano de Parto / Cartão da Gestante.
class PlanoPartoPdfService {
  const PlanoPartoPdfService();

  /// Gera os bytes do documento PDF.
  Future<Uint8List> generatePlanoPartoPdf({
    required GestanteModel? gestante,
    required GestacaoModel? gestacao,
    required HistoricoObstetricoModel? historico,
    required PlanoPartoModel? plano,
    String? firstUltrasound,
  }) async {
    final pdf = pw.Document(title: 'Plano de Parto - Meu Bebê', author: 'App Meu Bebê');

    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.openSansRegular();
      fontBold = await PdfGoogleFonts.openSansBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(theme: theme, pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(32)),
        header: (context) => _buildHeader(context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildIdentificationSection(gestante),
          pw.SizedBox(height: 12),
          _buildGestationAndObstetricSection(gestacao, historico, firstUltrasound),
          pw.SizedBox(height: 12),
          _buildPreferencesSection(plano),
          pw.SizedBox(height: 12),
          _buildLaborMomentSection(plano),
          pw.SizedBox(height: 12),
          _buildPainReliefSection(plano),
          pw.SizedBox(height: 12),
          _buildBirthAndBabySection(plano),
          pw.SizedBox(height: 12),
          _buildObservationsAndSignatures(plano),
        ],
      ),
    );

    return pdf.save();
  }

  /// Abre a interface nativa de pré-visualização, impressão e compartilhamento do PDF.
  Future<void> previewOrPrint({
    required BuildContext context,
    required GestanteModel? gestante,
    required GestacaoModel? gestacao,
    required HistoricoObstetricoModel? historico,
    required PlanoPartoModel? plano,
    String? firstUltrasound,
  }) async {
    final bytes = await generatePlanoPartoPdf(
      gestante: gestante,
      gestacao: gestacao,
      historico: historico,
      plano: plano,
      firstUltrasound: firstUltrasound,
    );

    await Printing.layoutPdf(
      name: 'plano_de_parto_${gestante?.nome.replaceAll(' ', '_') ?? 'gestante'}.pdf',
      onLayout: (format) async => bytes,
    );
  }

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.purple700, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MEU BEBE - PLANO DE PARTO',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.purple800),
              ),
              pw.Text(
                'Documento de Diretrizes e Preferências para a Assistência Obstétrica',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gerado pelo aplicativo Meu Bebe - Apoio ao Pre-Natal e Parto Humanizado',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            DateTime.now().toLocal().toString().substring(0, 16),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionCard({required String title, required List<pw.Widget> children}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: PdfColors.purple50,
              borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(5)),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFieldRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 170,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              (value != null && value.trim().isNotEmpty) ? value : 'Não informado',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIdentificationSection(GestanteModel? gestante) {
    return _buildSectionCard(
      title: '1. IDENTIFICAÇÃO DA GESTANTE',
      children: [
        _buildFieldRow('Nome civil', gestante?.nome),
        _buildFieldRow('Nome social', gestante?.nomeSocial),
        _buildFieldRow('Cartão SUS (CNS)', gestante?.cns),
        _buildFieldRow('CPF', gestante?.cpf),
        _buildFieldRow('Data de nascimento', gestante?.dataNascimento),
      ],
    );
  }

  pw.Widget _buildGestationAndObstetricSection(
    GestacaoModel? gestacao,
    HistoricoObstetricoModel? historico,
    String? firstUltrasound,
  ) {
    return _buildSectionCard(
      title: '2. DADOS DA GESTAÇÃO & HISTÓRICO OBSTÉTRICO',
      children: [
        _buildFieldRow('DUM (Última Menstruação)', gestacao?.dataUltimaMenstruacao),
        _buildFieldRow('Local do Pré-Natal', gestacao?.localPreNatal),
        _buildFieldRow('Profissional Responsável', gestacao?.profissionalPreNatal),
        _buildFieldRow('Contato da UBS/Clínica', gestacao?.contatoLocalPreNatal),
        _buildFieldRow('1ª Ultrassonografia', firstUltrasound),
        _buildFieldRow(
          'Histórico Obstétrico (G/P/A)',
          historico != null
              ? 'Gestações: ${historico.pregnancyNumber ?? 0} | Partos Anteriores: ${historico.givenBirthNumber ?? 0} | Abortos: ${historico.abortionsNumber ?? 0}'
              : 'Sem histórico registrado',
        ),
      ],
    );
  }

  pw.Widget _buildPreferencesSection(PlanoPartoModel? plano) {
    return _buildSectionCard(
      title: '3. AMBIENTE & TRABALHO DE PARTO (EXPECTATIVAS)',
      children: [
        _buildFieldRow('Presença de acompanhante', _formatTriState(plano?.acompanhante)),
        _buildFieldRow('Ambiente com pouca luz', _formatTriState(plano?.ambientePoucaLuz)),
        _buildFieldRow('Ouvir música de preferência', _formatTriState(plano?.ouvirMusica)),
        _buildFieldRow('Beber líquidos durante o trabalho', _formatTriState(plano?.beberLiquidos)),
        _buildFieldRow('Fotos e vídeos no parto', _formatTriState(plano?.registrarFotosVideos)),
        _buildFieldRow('Raspar pelos pubianos (tricotomia)', _formatTriState(plano?.rasparPelosIntimos)),
        _buildFieldRow('Lavagem intestinal (enema)', _formatTriState(plano?.lavagemIntestinal)),
      ],
    );
  }

  pw.Widget _buildLaborMomentSection(PlanoPartoModel? plano) {
    String posicao = 'Livre escolha';
    if (plano?.posicaoPreferida != null) {
      final posEnum = PosicaoParto.fromValue(plano!.posicaoPreferida);
      posicao = posEnum?.label ?? plano.posicaoPreferida!;
      if (posEnum == PosicaoParto.outra && plano.outraPosicao != null) {
        posicao += ' (${plano.outraPosicao})';
      }
    }

    return _buildSectionCard(
      title: '4. MOMENTO DO PARTO & PROCEDIMENTOS',
      children: [
        _buildFieldRow('Via de parto desejada', _formatViaParto(plano?.viaParto)),
        _buildFieldRow('Posição preferida para o parto', posicao),
        _buildFieldRow('Anestesia / Analgesia', _formatTriState(plano?.anestesia)),
        _buildFieldRow('Corte vaginal (episiotomia)', _formatTriState(plano?.corteVaginal)),
      ],
    );
  }

  pw.Widget _buildPainReliefSection(PlanoPartoModel? plano) {
    final metodos = <String>[];
    if (plano?.massagem == true) metodos.add('Massagem');
    if (plano?.exerciciosBola == true) metodos.add('Bola de pilates');
    if (plano?.exerciciosRespiracao == true) metodos.add('Exercícios de respiração');
    if (plano?.banhoChuveiro == true) metodos.add('Chuveiro morno');
    if (plano?.banhoBanheira == true) metodos.add('Banheira');
    if (plano?.acupuntura == true) metodos.add('Acupuntura');
    if (plano?.acupressao == true) metodos.add('Acupressão');
    if (plano?.outroMetodo == true) metodos.add('Outros métodos');

    final metodosTexto = metodos.isEmpty ? 'Nenhum método selecionado' : metodos.join(', ');

    return _buildSectionCard(
      title: '5. MÉTODOS NÃO FARMACOLÓGICOS DE ALÍVIO DA DOR',
      children: [
        _buildFieldRow('Deseja alívio não farmacológico', _formatTriState(plano?.querAlivioDor)),
        _buildFieldRow('Recursos e técnicas preferidas', metodosTexto),
      ],
    );
  }

  pw.Widget _buildBirthAndBabySection(PlanoPartoModel? plano) {
    return _buildSectionCard(
      title: '6. NASCIMENTO & CUIDADOS COM O RECÉM-NASCIDO',
      children: [
        _buildFieldRow('Quem corta o cordão umbilical', _formatActor(plano?.quemCortaCordao)),
        _buildFieldRow('Contato pele a pele imediato', _formatTriState(plano?.contatoPeleAPele)),
        _buildFieldRow('Amamentar na 1ª hora (Golden Hour)', _formatTriState(plano?.amamentarPrimeiraHora)),
        _buildFieldRow('Primeiro banho do bebê', _formatActor(plano?.primeiroBanho)),
        _buildFieldRow('Coleta de células-tronco', plano?.coletaCelulasTronco == true ? 'Sim' : 'Não'),
        _buildFieldRow('Restrições de amamentação', plano?.restricoesAmamentacao == true ? 'Sim' : 'Não'),
      ],
    );
  }

  pw.Widget _buildObservationsAndSignatures(PlanoPartoModel? plano) {
    final obs = (plano?.observacoes != null && plano!.observacoes.trim().isNotEmpty)
        ? plano.observacoes.trim()
        : 'Nenhuma observação adicional declarada.';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: '7. OBSERVAÇÕES & ORIENTAÇÕES ADICIONAIS',
          children: [pw.Text(obs, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900))],
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Column(
              children: [
                pw.Container(
                  width: 180,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700, width: 0.8)),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Assinatura da Gestante', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
              ],
            ),
            pw.Column(
              children: [
                pw.Container(
                  width: 180,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.grey700, width: 0.8)),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Profissional de Saúde Responsável',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatTriState(String? value) {
    if (value == null) return 'Não informado';
    return TriState.fromValue(value).label;
  }

  String _formatViaParto(String? value) {
    if (value == null) return 'Não informado';
    return ViaParto.fromValue(value).label;
  }

  String _formatActor(String? value) {
    if (value == null) return 'Não informado';
    return ActorChoice.fromValue(value).label;
  }
}
