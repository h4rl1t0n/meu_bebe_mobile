import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../../model/expectation.dart';
import '../../../../../widgets/base_card.dart';
import '../../../../../widgets/custom_item_tile.dart';

class ExpectationsCard extends StatelessWidget {
  const ExpectationsCard({super.key, required this.expectations, this.onEdit});

  final Expectation? expectations;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 20, color: context.colors.text),
              const SizedBox(width: 8),
              Text('Expectativas gerais', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Acompanhante', content: _getData(expectations?.companion)),
              const SizedBox(width: 10),
              CustomItemTile(
                flex: 1,
                title: 'Raspagem de pelos íntimos',
                content: _getData(expectations?.shaveIntimateHair),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(
                flex: 1,
                title: 'Lavagem instestinal',
                content: _getData(expectations?.bowelWashOrSuppository),
              ),
              const SizedBox(width: 10),
              CustomItemTile(
                flex: 1,
                title: 'Pouca luminosidade',
                content: _getData(expectations?.lowLightEnvironment),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Música', content: _getData(expectations?.listenToMusic)),
              const SizedBox(width: 10),
              CustomItemTile(flex: 1, title: 'Beber líquidos', content: _getData(expectations?.drinkLiquids)),
              const SizedBox(width: 10),
              CustomItemTile(
                flex: 1,
                title: 'Fotos e Filmagens',
                content: _getData(expectations?.recordPhotosOrVideos),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit, size: 18), label: const Text('Editar')),
          ),
        ],
      ),
    );
  }

  String _getData(Alternatives? alternative) {
    return switch (alternative) {
      Alternatives.yes => 'Sim',
      Alternatives.no => 'Não',
      Alternatives.dontKnow => 'Não sei',
      null => 'Não definido',
    };
  }
}
