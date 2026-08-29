import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../widgets/base_card.dart';
import '../../../../../widgets/custom_item_tile.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';

/// Card "Gestação atual" do resumo. Recebe a DUM da API (ISO) e a primeira
/// ultrassonografia (ISO) derivada de EXAMES — nunca um campo de GESTAÇÃO.
class CurrentGestationCard extends StatelessWidget {
  const CurrentGestationCard({
    super.key,
    required this.lastMenstrualPeriod,
    required this.firstUltrasound,
    this.onEdit,
  });

  /// `YYYY-MM-DD` (ISO) vinda da API.
  final String? lastMenstrualPeriod;

  /// Primeira ultrassonografia (`YYYY-MM-DD`) derivada de EXAMES (FASE 8F).
  final String? firstUltrasound;

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
              CustomItemTile(flex: 1, title: 'Última menstruação', content: _formatDate(lastMenstrualPeriod)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Data do ultrassom', content: _formatDate(firstUltrasound)),
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

  /// Exibe uma data ISO da API em `DD/MM/YYYY` (ou "Não informado").
  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Não informado';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  String _getGestationalAge() {
    final iso = lastMenstrualPeriod;
    if (iso == null || iso.isEmpty) return 'Sem dados';
    final menstrualDay = DateTime.tryParse(iso);
    if (menstrualDay == null) return 'Sem dados';
    final gestationalDays = DateTime.now().difference(menstrualDay).inDays;
    if (gestationalDays < 0) return 'Sem dados';
    return '${gestationalDays ~/ 7} semanas e ${gestationalDays % 7} dias';
  }

  String _getChildbirthDate() {
    final iso = lastMenstrualPeriod;
    if (iso == null || iso.isEmpty) return 'Sem dados';
    final menstrualDay = DateTime.tryParse(iso);
    if (menstrualDay == null) return 'Sem dados';
    final birth = menstrualDay.add(const Duration(days: 280));
    return '${birth.day.toString().padLeft(2, '0')}/${birth.month.toString().padLeft(2, '0')}/${birth.year}';
  }
}
