import 'package:flutter/material.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../../model/pain_relief.dart';
import '../../../../../widgets/base_card.dart';
import '../../../../../widgets/custom_item_tile.dart';

class PainReliefCard extends StatelessWidget {
  const PainReliefCard({super.key, required this.painRelief, this.onEdit});

  final PainRelief? painRelief;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.healing, size: 20, color: context.colors.text),
              const SizedBox(width: 8),
              Text('Medidas para alívio da dor', style: context.textStyles.titleSmallStyle),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(
                flex: 1,
                title: 'Deseja alívio da dor?',
                content: _needPainReliefToString(painRelief?.painRelief),
              ),
            ],
          ),
          if (_activeMethods.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [CustomItemTile(flex: 1, title: 'Métodos escolhidos', content: _activeMethods)],
            ),
          ],
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

  String get _activeMethods {
    if (painRelief == null) return 'Não definido';
    if (painRelief!.painRelief == NeedPainRelief.no || painRelief!.painRelief == NeedPainRelief.dontKnow) {
      return 'Nenhum';
    }
    final methods = <String>[];
    if (painRelief!.massage) methods.add('Massagem');
    if (painRelief!.ballExercises) methods.add('Bola');
    if (painRelief!.breathRelaxExercises) methods.add('Respiração');
    if (painRelief!.showerBath) methods.add('Chuveiro');
    if (painRelief!.bathtubBath) methods.add('Banheira');
    if (painRelief!.acupuncture) methods.add('Acupuntura');
    if (painRelief!.acupressure) methods.add('Acupressão');
    if (painRelief!.otherMethod) methods.add('Outro');
    return methods.isEmpty ? 'Nenhum' : methods.join(', ');
  }

  String _needPainReliefToString(NeedPainRelief? v) {
    return switch (v) {
      NeedPainRelief.yes => 'Sim',
      NeedPainRelief.no => 'Não',
      NeedPainRelief.dontKnow => 'Não sei',
      null => 'Não definido',
    };
  }
}
