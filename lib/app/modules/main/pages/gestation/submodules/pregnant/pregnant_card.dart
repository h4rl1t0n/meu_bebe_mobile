import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/current_pregnancy_data.dart';
import '../../../../../../model/pregnant_data.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/custom_item_tile.dart';

class PregnantCard extends StatelessWidget {
  const PregnantCard({super.key, required this.pregnantData, required this.currentPregnancy, this.onEdit});

  final PregnantData? pregnantData;
  final CurrentPregnancyData? currentPregnancy;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Identificacao', style: context.textStyles.titleSmallStyle),
          const SizedBox(height: 16),
          Row(
            spacing: 10,
            children: [
              CustomItemTile(flex: 3, title: 'Nome', content: _getData(pregnantData?.name)),
              CustomItemTile(flex: 1, title: 'Idade', content: _getAge()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            spacing: 10,
            children: [
              CustomItemTile(flex: 1, title: 'IG atual', content: _getGestationalAge()),
              CustomItemTile(flex: 1, title: 'Data do parto', content: _getChildbirthDate()),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CustomItemTile(
                flex: 1,
                title: 'Local que realiza o pre-natal',
                content: _getData(pregnantData?.prenatalPlace),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CustomItemTile(flex: 1, title: 'Nome do profissional', content: _getData(pregnantData?.professionalName)),
              const SizedBox(width: 10),
              CustomItemTile(flex: 1, title: 'Contato do local', content: _getData(pregnantData?.prenatalPlaceContact)),
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

  String _getData(String? raw) {
    if (raw == null || raw.isEmpty) return 'Nao informado';
    return raw;
  }

  String _getAge() {
    final birthDate = pregnantData?.birthDate;
    if (birthDate == null || birthDate.isEmpty) return 'Nao informado';
    try {
      final formatted = '${birthDate.substring(6, 10)}-${birthDate.substring(3, 5)}-${birthDate.substring(0, 2)}';
      final birth = DateTime.parse(formatted);
      final now = DateTime.now();
      final age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        return '${age - 1} anos';
      }
      return '$age anos';
    } catch (_) {
      return 'Nao informado';
    }
  }

  String _getGestationalAge() {
    final lmp = currentPregnancy?.lastMenstrualPeriod;
    if (lmp == null || lmp.isEmpty) return 'Sem dados';
    try {
      final formatted = '${lmp.substring(6, 10)}-${lmp.substring(3, 5)}-${lmp.substring(0, 2)}';
      final menstrualDay = DateTime.parse(formatted);
      final gestationalDays = DateTime.now().difference(menstrualDay).inDays;
      return '${gestationalDays ~/ 7} semanas e ${gestationalDays % 7} dias';
    } catch (_) {
      return 'Sem dados';
    }
  }

  String _getChildbirthDate() {
    final lmp = currentPregnancy?.lastMenstrualPeriod;
    if (lmp == null || lmp.isEmpty) return 'Sem dados';
    try {
      final formatted = '${lmp.substring(6, 10)}-${lmp.substring(3, 5)}-${lmp.substring(0, 2)}';
      final menstrualDay = DateTime.parse(formatted);
      final birth = menstrualDay.add(const Duration(days: 280));
      return '${birth.day.toString().padLeft(2, '0')}/${birth.month.toString().padLeft(2, '0')}/${birth.year}';
    } catch (_) {
      return 'Sem dados';
    }
  }
}
