import 'package:flutter/material.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/item_tile_with_list.dart';

class PrenatalAppointmentCard extends StatelessWidget {
  const PrenatalAppointmentCard({super.key, required this.list});

  final List<String> list;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [ItemTileWithList(title: 'Consultas de pré-natal', list: list)],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Messages.showInfo('Ainda não implementado');
              },
              child: const Text('Adicionar consulta'),
            ),
          ),
        ],
      ),
    );
  }
}
