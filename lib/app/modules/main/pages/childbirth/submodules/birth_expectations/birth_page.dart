import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../widgets/base_card.dart';
import 'birth_controller.dart';
import 'birth_form_controller.dart';

class BirthPage extends StatefulWidget {
  const BirthPage({super.key});

  @override
  State<BirthPage> createState() => _BirthPageState();
}

class _BirthPageState extends State<BirthPage> with BirthFormController {
  final _controller = Modular.get<BirthController>();
  late ReactionDisposer _reactionDisposer;

  @override
  void initState() {
    super.initState();
    // Re-hidrata o formulário sempre que `plano` (observable) mudar, para que
    // os dados persistidos apareçam SEM interação do usuário.
    _reactionDisposer = reaction(
      (_) => _controller.plano,
      (plano) {
        initializeForm(plano);
        if (mounted) setState(() {});
      },
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _reactionDisposer();
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    return Observer(
      builder: (_) {
        if (_controller.saved) {
          _controller.saved = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Modular.to.pop();
          });
        }
        return Scaffold(
          appBar: AppBar(title: Text('Nascimento', style: textStyles.titleSmallStyle), centerTitle: true),
          body: Container(
            padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
            child: SingleChildScrollView(
              child: BaseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expectativas para o nascimento', style: textStyles.titleSmallStyle),
                    SizedBox(height: Spacing.lg),
                    Text('Quem cortará o cordão umbilical?', style: textStyles.textStyle),
                    SizedBox(height: Spacing.sm),
                    _buildActorTabBar(whoCutEC),
                    SizedBox(height: Spacing.lg),
                    _buildSwitchTile(
                      'Coleta de células-tronco?',
                      collectStemCells,
                      (v) => setState(() => collectStemCells = v),
                    ),
                    SizedBox(height: Spacing.lg),
                    Text('Contato pele a pele?', style: textStyles.textStyle),
                    SizedBox(height: Spacing.sm),
                    _buildTriTabBar(skinBabyContactEC),
                    SizedBox(height: Spacing.lg),
                    Text('Amamentação na primeira hora?', style: textStyles.textStyle),
                    SizedBox(height: Spacing.sm),
                    _buildTriTabBar(breastfeedFirstHourEC),
                    SizedBox(height: Spacing.lg),
                    _buildSwitchTile(
                      'Restrições à amamentação?',
                      breastfeedRestrictions,
                      (v) => setState(() => breastfeedRestrictions = v),
                    ),
                    SizedBox(height: Spacing.lg),
                    Text('Primeiro banho do bebê por?', style: textStyles.textStyle),
                    SizedBox(height: Spacing.sm),
                    _buildActorTabBar(firstBathEC),
                    SizedBox(height: Spacing.xxl),
                    _saveButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActorTabBar(TextEditingController controller) {
    return Row(
      spacing: 5,
      children: ActorChoice.values.map((v) {
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => controller.text = v.value),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: RadiusTokens.mdAll,
                border: Border.all(color: context.colors.darkText),
                color: controller.text == v.value ? context.colors.secondary : context.colors.surface,
                boxShadow: [ElevationTokens.subtleShadow(Theme.of(context).colorScheme.onSurface)],
              ),
              child: Text(v.label, style: context.textStyles.caption, textAlign: TextAlign.center),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTriTabBar(TextEditingController controller) {
    return Row(
      spacing: 5,
      children: TriState.values.map((v) {
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => controller.text = v.value),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: RadiusTokens.mdAll,
                border: Border.all(color: context.colors.darkText),
                color: controller.text == v.value ? context.colors.secondary : context.colors.surface,
                boxShadow: [ElevationTokens.subtleShadow(Theme.of(context).colorScheme.onSurface)],
              ),
              child: Text(v.label, style: context.textStyles.caption, textAlign: TextAlign.center),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSwitchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        title: Text(label, style: context.textStyles.textStyle),
        value: value,
        onChanged: onChanged,
        activeThumbColor: context.colors.text,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }

  SizedBox _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          _controller.saveBirth(
            quemCortaCordao: actor(whoCutEC),
            coletaCelulasTronco: collectStemCells,
            contatoPeleAPele: triState(skinBabyContactEC),
            amamentarPrimeiraHora: triState(breastfeedFirstHourEC),
            restricoesAmamentacao: breastfeedRestrictions,
            primeiroBanho: actor(firstBathEC),
          );
        },
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Salvar'),
      ),
    );
  }
}
