import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../app_module.dart';
import '../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../widgets/base_card.dart';
import '../../../../../core/ui/theme/styles/design_tokens.dart';

class UpdateChildbirthCard extends StatelessWidget {
  const UpdateChildbirthCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        spacing: 10,
        children: [
          Text('Atualize seu plano de parto', style: context.textStyles.titleSmallStyle),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              _buildButton('Identificação', () {
                Modular.to.pushNamed(routeIndetificacao);
              }),
              const SizedBox(width: Spacing.sm),
              _buildButton('História', () {
                Modular.to.pushNamed(routeHistoria);
              }),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              _buildButton('Gravidez atual', () {
                Modular.to.pushNamed(routeGravidezAtual);
              }),
              const SizedBox(width: Spacing.sm),
              _buildButton('Expectativas', () {
                Modular.to.pushNamed(routeExpectativa);
              }),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [_buildButton('Parto', () => Modular.to.pushNamed(routeMomentoParto)), const SizedBox(width: Spacing.sm), _buildButton('Alívio da dor', () => Modular.to.pushNamed(routeAlivioDor))],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              _buildButton('Nascimento', () => Modular.to.pushNamed(routeNascimento)),
              const SizedBox(width: Spacing.sm),
              _buildButton('Observações', () => Modular.to.pushNamed(routeObservacoes)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String title, VoidCallback onPressed) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: ElevatedButton(onPressed: onPressed, child: Text(title)),
      ),
    );
  }
}
