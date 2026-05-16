import 'package:flutter/material.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../core/ui/theme/styles/colors_app.dart';
import 'widgets/information_card.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.secondary,
      appBar: AppBar(title: const Text('Mais Informacoes'), centerTitle: true),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: InformationCard(icon: Icons.girl_outlined, title: 'Mudancas no corpo', onTap: () => Messages.showInfo('Em breve')),
                ),
                Expanded(
                  child: InformationCard(icon: Icons.pregnant_woman, title: 'Minha gravidez', onTap: () => Messages.showInfo('Em breve')),
                ),
              ],
            ),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: InformationCard(icon: Icons.watch_later_outlined, title: 'Chegou a hora', onTap: () => Messages.showInfo('Em breve')),
                ),
                Expanded(
                  child: InformationCard(icon: Icons.baby_changing_station, title: 'Apos o parto', onTap: () => Messages.showInfo('Em breve')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
