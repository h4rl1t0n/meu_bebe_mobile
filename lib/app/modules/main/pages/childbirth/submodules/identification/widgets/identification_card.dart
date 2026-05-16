import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../../model/pregnant_data.dart';
import '../../../../../widgets/base_card.dart';
import '../../../../../widgets/custom_item_tile.dart';

class IdentificationCard extends StatelessWidget {
  const IdentificationCard({super.key, required this.pregnantData, this.onEdit});

  final PregnantData? pregnantData;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: context.colors.text),
              const SizedBox(width: 8),
              Text('Identificação', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [CustomItemTile(flex: 1, title: 'Nome da gestante', content: getData(pregnantData?.name))],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 3, title: 'Prefere ser chamada', content: getData(pregnantData?.socialName)),
              const SizedBox(width: 10),
              CustomItemTile(flex: 1, title: 'Idade', content: _getAge()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(
                flex: 1,
                title: 'Cartão Nacional de Saúde',
                content: getData(pregnantData?.nationalHealthCard),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Local do pré-natal', content: getData(pregnantData?.prenatalPlace)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Profissional', content: getData(pregnantData?.professionalName)),
              const SizedBox(width: 10),
              CustomItemTile(flex: 1, title: 'Telefone', content: getData(pregnantData?.prenatalPlaceContact)),
            ],
          ),
          const SizedBox(height: 10),
          // const Row(
          //   crossAxisAlignment: CrossAxisAlignment.end,
          //   children: [
          //     CustomItemTile(
          //       flex: 1,
          //       title: 'Maternidade',
          //       content: 'Maternidade Benção',
          //     ),
          //   ],
          // ),
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

  String _getAge() {
    if (pregnantData?.birthDate?.isNotEmpty == true) {
      final birth = DateTime.parse(_transformDate(pregnantData!.birthDate!));
      final today = DateTime.now();
      log(today.toString());
      final age = today.difference(birth);
      log((age.inDays / 365.25).toInt().toString());
      return (age.inDays / 365.25).toInt().toString();
    }
    return '-';
  }

  String _transformDate(String date) {
    final formatted = '${date.substring(6, 10)}-${date.substring(3, 5)}-${date.substring(0, 2)}';
    log(formatted);
    return formatted;
  }

  String getData(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Não informado';
    } else {
      return raw;
    }
  }
}
