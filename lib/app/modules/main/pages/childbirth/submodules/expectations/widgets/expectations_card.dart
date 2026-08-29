import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../../model/plano_parto/plano_parto_model.dart';
import '../../../../../widgets/base_card.dart';
import '../../../../../widgets/custom_item_tile.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';

class ExpectationsCard extends StatelessWidget {
  const ExpectationsCard({super.key, required this.plano, this.onEdit});

  final PlanoPartoModel? plano;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 20, color: context.colors.text),
              const SizedBox(width: Spacing.sm),
              Text('Expectativas gerais', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Acompanhante', content: _tri(plano?.acompanhante)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(
                flex: 1,
                title: 'Raspagem de pelos íntimos',
                content: _tri(plano?.rasparPelosIntimos),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(
                flex: 1,
                title: 'Lavagem instestinal',
                content: _tri(plano?.lavagemIntestinal),
              ),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(
                flex: 1,
                title: 'Pouca luminosidade',
                content: _tri(plano?.ambientePoucaLuz),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Música', content: _tri(plano?.ouvirMusica)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Beber líquidos', content: _tri(plano?.beberLiquidos)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(
                flex: 1,
                title: 'Fotos e Filmagens',
                content: _tri(plano?.registrarFotosVideos),
              ),
            ],
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

  String _tri(String? value) =>
      value == null ? 'Não definido' : TriState.fromValue(value).label;
}
