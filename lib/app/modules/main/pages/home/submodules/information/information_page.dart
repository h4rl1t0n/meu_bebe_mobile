import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import 'widgets/information_card.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.secondary,
      appBar: AppBar(title: const Text('Mais Informacoes'), centerTitle: true),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: InformationCard(
                    icon: Icons.girl_outlined,
                    title: 'Mudancas no corpo',
                    onTap: () => _showInfoDialog(
                      context,
                      'Mudancas no Corpo',
                      'Durante a gestacao, seu corpo passa por diversas transformacoes:\n\n'
                          '• Aumento do volume abdominal\n'
                          '• Alteracoes hormonais\n'
                          '• Mudancas nos seios\n'
                          '• Aumento de peso\n'
                          '• Alteracoes na pele (estrias, melasma)\n'
                          '• Inchaço nas pernas e pes\n\n'
                          'Converse com seu medico sobre qualquer mudanca que a preocupe.',
                    ),
                  ),
                ),
                Expanded(
                  child: InformationCard(
                    icon: Icons.pregnant_woman,
                    title: 'Minha gravidez',
                    onTap: () => _showInfoDialog(
                      context,
                      'Minha Gravidez',
                      'A gestacao e dividida em tres trimestres:\n\n'
                          '• 1° trimestre (0-13 semanas): Formacao dos orgaos do bebe\n'
                          '• 2° trimestre (14-26 semanas): Crescimento e desenvolvimento\n'
                          '• 3° trimestre (27-40 semanas): Preparacao para o parto\n\n'
                          'Mantenha seu pre-natal em dia e tire todas as duvidas com o profissional de saude.',
                    ),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: InformationCard(
                    icon: Icons.watch_later_outlined,
                    title: 'Chegou a hora',
                    onTap: () => _showInfoDialog(
                      context,
                      'Chegou a Hora',
                      'Sinais de trabalho de parto:\n\n'
                          '• Contracoes regulares e ritmicas\n'
                          '• Ruptura da bolsa (perda de liquido)\n'
                          '• Perda do tampao mucoso\n'
                          '• Dor lombar persistente\n\n'
                          'Ao notar estes sinais, entre em contato com seu medico ou dirija-se a maternidade.',
                    ),
                  ),
                ),
                Expanded(
                  child: InformationCard(
                    icon: Icons.baby_changing_station,
                    title: 'Apos o parto',
                    onTap: () => _showInfoDialog(
                      context,
                      'Apos o Parto',
                      'O pos-parto (puerperio) e um periodo de recuperacao e adaptacao:\n\n'
                          '• Amamentacao: Ofereca o peito ao bebe logo apos o parto\n'
                          '• Repouso: Descanse sempre que possivel\n'
                          '• Alimentacao: Mantenha uma dieta equilibrada\n'
                          '• Emocoes: E normal sentir oscilacoes de humor\n'
                          '• Consulta pos-parto: Agende para 7-10 dias apos o parto\n\n'
                          'Nao hesite em buscar ajuda se sentir tristeza persistente.',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: context.textStyles.titleSmallStyle),
        content: SingleChildScrollView(child: Text(content, style: context.textStyles.textStyle)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }
}
