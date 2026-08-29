import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/vacina/vacina_catalogo.dart';
import 'vaccines_controller.dart';
import 'widgets/vaccine_card.dart';

class VaccinesPage extends StatefulWidget {
  const VaccinesPage({super.key});

  @override
  State<VaccinesPage> createState() => _VaccinesPageState();
}

class _VaccinesPageState extends State<VaccinesPage> {
  final controller = Modular.get<VaccinesController>();

  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text('Minhas Vacinas', style: textStyles.titleSmallStyle),
        centerTitle: true,
      ),
      body: Observer(
        builder: (_) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!controller.hasGestacao) {
            return Center(
              child: Text(
                'Cadastre sua gestação para marcar vacinas.',
                textAlign: TextAlign.center,
                style: textStyles.subTitleStyle,
              ),
            );
          }

          final qualquerTempo = VacinaCatalogo.itens.where((i) => !i.tpa);
          final tpa = VacinaCatalogo.itens.where((i) => i.tpa);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.pageH,
              vertical: Spacing.pageV,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text('Qualquer tempo', style: textStyles.titleSmallStyle),
                ),
                const SizedBox(height: Spacing.sm),
                for (final item in qualquerTempo) _buildCard(item),
                const SizedBox(height: Spacing.xxxl),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    '20ª semana de gravidez até 45 dias após o parto',
                    textAlign: TextAlign.center,
                    style: textStyles.titleSmallStyle,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                for (final item in tpa) _buildCard(item),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(VacinaCatalogoItem item) {
    final vacina = controller.vacinaPorNome(item.nome);
    return VaccineCard(
      title: item.titulo,
      info: item.info,
      used: vacina?.aplicada ?? false,
      onChanged: () => controller.toggleVacina(item.nome),
    );
  }
}
