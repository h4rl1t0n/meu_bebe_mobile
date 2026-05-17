import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../app_module.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/item_tile_with_list.dart';

class PregnancyHistoryCard extends StatelessWidget {
  const PregnancyHistoryCard({super.key, required this.list});

  final List<String> list;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: ItemTileWithList(title: 'Historico de gestacoes', list: list)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Modular.to.pushNamed(routeHistoria),
              child: const Text('Editar historico'),
            ),
          ),
        ],
      ),
    );
  }
}
