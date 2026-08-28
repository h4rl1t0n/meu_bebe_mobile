import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/custom_item_tile.dart';

/// Card "Identificação" da Aba Gestação. Recebe valores simples já vindos da
/// API (gestante + gestação), nunca modelos SQLite.
class PregnantCard extends StatelessWidget {
  const PregnantCard({
    super.key,
    required this.name,
    required this.birthDate,
    required this.lastMenstrualPeriod,
    required this.localPreNatal,
    required this.profissionalPreNatal,
    required this.contatoLocalPreNatal,
    this.onEdit,
  });

  final String? name;

  /// `YYYY-MM-DD` (ISO) vinda da API.
  final String? birthDate;

  /// `YYYY-MM-DD` (ISO) vinda da API.
  final String? lastMenstrualPeriod;

  final String? localPreNatal;
  final String? profissionalPreNatal;
  final String? contatoLocalPreNatal;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Identificacao', style: context.textStyles.titleSmallStyle),
          const SizedBox(height: Spacing.lg),
          Row(
            spacing: 10,
            children: [
              CustomItemTile(flex: 3, title: 'Nome', content: _getData(name)),
              CustomItemTile(flex: 1, title: 'Idade', content: _getAge()),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            spacing: 10,
            children: [
              CustomItemTile(flex: 1, title: 'IG atual', content: _getGestationalAge()),
              CustomItemTile(flex: 1, title: 'Data do parto', content: _getChildbirthDate()),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              CustomItemTile(
                flex: 1,
                title: 'Local que realiza o pre-natal',
                content: _getData(localPreNatal),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              CustomItemTile(flex: 1, title: 'Nome do profissional', content: _getData(profissionalPreNatal)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Contato do local', content: _getData(contatoLocalPreNatal)),
            ],
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

  String _getData(String? raw) {
    if (raw == null || raw.isEmpty) return 'Nao informado';
    return raw;
  }

  String _getAge() {
    final iso = birthDate;
    if (iso == null || iso.isEmpty) return 'Nao informado';
    final birth = DateTime.tryParse(iso);
    if (birth == null) return 'Nao informado';
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age -= 1;
    }
    return '$age anos';
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
