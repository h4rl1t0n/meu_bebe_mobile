import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/birth_moment.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/custom_item_tile.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';

class BirthMomentCard extends StatelessWidget {
  const BirthMomentCard({super.key, required this.birthMoment, this.onEdit});

  final BirthMoment? birthMoment;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.child_care, size: 20, color: context.colors.text),
              const SizedBox(width: Spacing.sm),
              Text('Expectativas para o momento do parto', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Via de parto', content: _birthWayToString(birthMoment?.birthWay)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Corte vaginal', content: _vaginalCutToString(birthMoment?.vaginalCut)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Anestesia', content: _anesthesiaToString(birthMoment?.anesthesia)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Posição', content: _positionToString()),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [CustomItemTile(flex: 1, title: 'Medidas para aliviar a dor', content: 'Ver em Alívio da dor')],
          ),
          const SizedBox(height: Spacing.lg),
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

  String _birthWayToString(BirthWay? v) {
    return switch (v) {
      BirthWay.vaginal => 'Vaginal',
      BirthWay.cesarean => 'Cesárea',
      BirthWay.dontKnow => 'Não sei',
      null => 'Não definido',
    };
  }

  String _anesthesiaToString(Anesthesia? v) {
    return switch (v) {
      Anesthesia.yes => 'Sim',
      Anesthesia.no => 'Não',
      Anesthesia.dontKnow => 'Não sei',
      null => 'Não definido',
    };
  }

  String _vaginalCutToString(VaginalCut? v) {
    return switch (v) {
      VaginalCut.yes => 'Sim',
      VaginalCut.no => 'Não',
      VaginalCut.dontKnow => 'Não sei',
      null => 'Não definido',
    };
  }

  String _positionToString() {
    if (birthMoment == null) return 'Não definido';
    if (birthMoment!.otherPosition != null && birthMoment!.otherPosition!.isNotEmpty) {
      return birthMoment!.otherPosition!;
    }
    return switch (birthMoment!.preferredPosition) {
      Positions.lyingDown => 'Deitada',
      Positions.sitting => 'Sentada',
      Positions.crouched => 'Agachada',
      Positions.aside => 'De lado',
      Positions.onKnees => 'De joelhos',
      Positions.standing => 'Em pé',
      Positions.dontKnow => 'Não sei',
      Positions.otherPosition => 'Outra',
      null => 'Não definido',
    };
  }
}
