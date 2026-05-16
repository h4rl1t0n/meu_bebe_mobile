import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/birth.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/custom_item_tile.dart';

class BirthExpectationsCard extends StatelessWidget {
  const BirthExpectationsCard({super.key, required this.birth, this.onEdit});

  final Birth? birth;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.crib, size: 20, color: context.colors.text),
              const SizedBox(width: 8),
              Text('Expectativas para o nascimento', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Corte do cordão', content: _whoCutToString(birth?.whoCut)),
              const SizedBox(width: 10),
              CustomItemTile(
                flex: 1,
                title: 'Contato pele a pele',
                content: _skinContactToString(birth?.skinBabyContact),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Amamentação', content: _breastfeedToString(birth?.breastfeedFirstHour)),
              const SizedBox(width: 10),
              CustomItemTile(flex: 1, title: '1° banho', content: _firstBathToString(birth?.firstBath)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Editar'),
            ),
          ),
        ],
      ),
    );
  }

  String _whoCutToString(WhoCutUmbilicalCord? v) {
    return switch (v) {
      WhoCutUmbilicalCord.professional => 'Profissional',
      WhoCutUmbilicalCord.companion => 'Acompanhante',
      WhoCutUmbilicalCord.me => 'Eu',
      WhoCutUmbilicalCord.dontKnow => 'Não sei',
      null => 'Não definido',
    };
  }

  String _skinContactToString(SkinBabyContact? v) {
    return switch (v) {
      SkinBabyContact.yes => 'Sim',
      SkinBabyContact.no => 'Não',
      SkinBabyContact.dontKnow => 'Não sei',
      null => 'Não definido',
    };
  }

  String _breastfeedToString(BreastfeedFirstHour? v) {
    return switch (v) {
      BreastfeedFirstHour.yes => 'Sim',
      BreastfeedFirstHour.no => 'Não',
      BreastfeedFirstHour.dontKnow => 'Não sei',
      null => 'Não definido',
    };
  }

  String _firstBathToString(FirstBath? v) {
    return switch (v) {
      FirstBath.professional => 'Profissional',
      FirstBath.companion => 'Acompanhante',
      FirstBath.me => 'Eu',
      FirstBath.dontKnow => 'Não sei',
      null => 'Não definido',
    };
  }
}
