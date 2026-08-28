import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../widgets/base_card.dart';
import '../../../../../widgets/custom_item_tile.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';

/// Card "Identificação" do resumo. Recebe valores simples já vindos da API
/// (gestante + gestação), nunca modelos SQLite.
class IdentificationCard extends StatelessWidget {
  const IdentificationCard({
    super.key,
    required this.name,
    required this.socialName,
    required this.birthDate,
    required this.nationalHealthCard,
    required this.localPreNatal,
    required this.profissionalPreNatal,
    required this.contatoLocalPreNatal,
    this.onEdit,
  });

  final String? name;
  final String? socialName;

  /// `YYYY-MM-DD` (ISO) vinda da API.
  final String? birthDate;

  final String? nationalHealthCard;
  final String? localPreNatal;
  final String? profissionalPreNatal;
  final String? contatoLocalPreNatal;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: context.colors.text),
              const SizedBox(width: Spacing.sm),
              Text('Identificação', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [CustomItemTile(flex: 1, title: 'Nome da gestante', content: _getData(name))],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 3, title: 'Prefere ser chamada', content: _getData(socialName)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Idade', content: _getAge()),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(
                flex: 1,
                title: 'Cartão Nacional de Saúde',
                content: _getData(nationalHealthCard),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Local do pré-natal', content: _getData(localPreNatal)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Profissional', content: _getData(profissionalPreNatal)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Telefone', content: _getData(contatoLocalPreNatal)),
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

  String _getAge() {
    final iso = birthDate;
    if (iso == null || iso.isEmpty) return '-';
    final birth = DateTime.tryParse(iso);
    if (birth == null) return '-';
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age -= 1;
    }
    return '$age';
  }

  String _getData(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Não informado';
    } else {
      return raw;
    }
  }
}
