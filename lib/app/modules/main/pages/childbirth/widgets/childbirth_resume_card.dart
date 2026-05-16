import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../app_module.dart';
import '../../../../../core/helpers/messages.dart';
import '../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../widgets/base_card.dart';
import '../../../widgets/custom_item_tile.dart';

class ChildbirthResumeCard extends StatelessWidget {
  const ChildbirthResumeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Text('Resumo do plano de parto', style: context.textStyles.titleSmallStyle),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Via de parto', content: 'Não definido'),
              SizedBox(width: 10),
              CustomItemTile(flex: 1, title: 'Posição', content: 'Não definido'),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Anestesia', content: 'Não definido'),
              SizedBox(width: 10),
              CustomItemTile(flex: 1, title: 'Acompanhante', content: 'Não definido'),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Corte cordão', content: 'Não definido'),
              SizedBox(width: 10),
              CustomItemTile(flex: 1, title: '1° banho', content: 'Não definido'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Modular.to.pushNamed(routeVisualizarResumo);
                    },
                    child: const Text('Visualizar'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Messages.showInfo('Ainda não implementado');
                    },
                    child: const Text('Compartilhar'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
