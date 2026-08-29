import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../../model/plano_parto/plano_parto_model.dart';
import '../../../../../widgets/base_card.dart';
import '../../../../../widgets/custom_item_tile.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';

class PainReliefCard extends StatelessWidget {
  const PainReliefCard({super.key, required this.plano, this.onEdit});

  final PlanoPartoModel? plano;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.healing, size: 20, color: context.colors.text),
              const SizedBox(width: Spacing.sm),
              Text('Medidas para alívio da dor', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(
                flex: 1,
                title: 'Deseja alívio da dor?',
                content: _tri(plano?.querAlivioDor),
              ),
            ],
          ),
          if (_activeMethods.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [CustomItemTile(flex: 1, title: 'Métodos escolhidos', content: _activeMethods)],
            ),
          ],
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

  String _tri(String? v) =>
      v == null ? 'Não definido' : TriState.fromValue(v).label;

  String get _activeMethods {
    final data = plano;
    if (data == null) return 'Não definido';
    final quer = TriState.fromValue(data.querAlivioDor);
    if (quer == TriState.nao || quer == TriState.naoSei) {
      return 'Nenhum';
    }
    final methods = <String>[];
    if (data.massagem) methods.add('Massagem');
    if (data.exerciciosBola) methods.add('Bola');
    if (data.exerciciosRespiracao) methods.add('Respiração');
    if (data.banhoChuveiro) methods.add('Chuveiro');
    if (data.banhoBanheira) methods.add('Banheira');
    if (data.acupuntura) methods.add('Acupuntura');
    if (data.acupressao) methods.add('Acupressão');
    if (data.outroMetodo) methods.add('Outro');
    return methods.isEmpty ? 'Nenhum' : methods.join(', ');
  }
}
