import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/custom_item_tile.dart';

class BirthMomentCard extends StatelessWidget {
  const BirthMomentCard({super.key, required this.plano, this.onEdit});

  final PlanoPartoModel? plano;
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
              Flexible(child: Text('Expectativas para o momento do parto', style: context.textStyles.titleSmallStyle)),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Via de parto', content: _via(plano?.viaParto)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Corte vaginal', content: _tri(plano?.corteVaginal)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Anestesia', content: _tri(plano?.anestesia)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Posição', content: _position()),
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

  String _via(String? v) =>
      v == null ? 'Não definido' : ViaParto.fromValue(v).label;

  String _tri(String? v) =>
      v == null ? 'Não definido' : TriState.fromValue(v).label;

  String _position() {
    final data = plano;
    if (data == null) return 'Não definido';
    final outra = data.outraPosicao;
    if (outra != null && outra.isNotEmpty) return outra;
    final pos = data.posicaoPreferida;
    if (pos == null || pos.isEmpty) return 'Não definido';
    return PosicaoParto.fromValue(pos)?.label ?? 'Não definido';
  }
}
