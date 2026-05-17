import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../../model/current_pregnancy_data.dart';
import '../../../../../widgets/base_card.dart';
import '../../../../../widgets/custom_item_tile.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';

class CurrentGestationCard extends StatelessWidget {
  const CurrentGestationCard({super.key, required this.current, this.onEdit});

  final CurrentPregnancyData? current;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pregnant_woman, size: 20, color: context.colors.text),
              const SizedBox(width: Spacing.sm),
              Text('Gestação atual', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Última menstruação', content: _getData(current?.lastMenstrualPeriod)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Data do ultrassom', content: _getData(current?.firstUltrasound)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Idade Gestacional aproximada', content: _getGestationalAge()),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Data provável do parto', content: _getChildbirthDate()),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [CustomItemTile(flex: 1, title: 'Sobre a minha gravidez atual', content: '')],
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit, size: 18), label: const Text('Editar')),
          ),
        ],
      ),
    );
  }

  String _getData(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Não informado';
    } else {
      return raw;
    }
  }

  String _getGestationalAge() {
    if (current?.lastMenstrualPeriod != null) {
      final now = DateTime.now();
      final menstrualDay = DateTime.parse(_transformDate(current!.lastMenstrualPeriod!));
      final gestationalDays = now.difference(menstrualDay).inDays;
      return '${gestationalDays ~/ 7} semanas e ${gestationalDays % 7} dias';
    }
    return 'Sem dados';
  }

  String _getChildbirthDate() {
    if (current?.lastMenstrualPeriod != null) {
      final menstrualDay = DateTime.parse(_transformDate(current!.lastMenstrualPeriod!));
      final birth = menstrualDay.add(const Duration(days: 280));
      return _dateTimeToString(birth);
    }

    return 'Sem dados';
  }

  String _transformDate(String date) {
    final formatted = '${date.substring(6, 10)}-${date.substring(3, 5)}-${date.substring(0, 2)}';
    return formatted;
  }

  String _dateTimeToString(DateTime date) {
    final rawDate = date.toString();
    return '${rawDate.substring(8, 10)}/${rawDate.substring(5, 7)}/${rawDate.substring(0, 4)}';
  }
}
