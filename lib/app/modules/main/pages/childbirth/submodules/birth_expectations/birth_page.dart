import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/birth.dart';
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

  int _parseSafely(TextEditingController ctrl, {int fallback = 0}) {
    final text = ctrl.text;
    if (text.isEmpty) return fallback;
    return int.tryParse(text) ?? fallback;
  }

  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          initializeForm(_controller.birth);
        }
      });
    });
  }

  @override
  void dispose() {
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
                    _buildTabBar(whoCutEC, const ['Profissional', 'Acompanhante', 'Eu', 'Não sei']),
                    SizedBox(height: Spacing.lg),
                    _buildSwitchTile(
                      'Coleta de células-tronco?',
                      collectStemCells,
                      (v) => setState(() => collectStemCells = v),
                    ),
                    SizedBox(height: Spacing.lg),
                    Text('Contato pele a pele?', style: textStyles.textStyle),
                    SizedBox(height: Spacing.sm),
                    _buildTabBar(skinBabyContactEC, const ['Sim', 'Não', 'Não sei']),
                    SizedBox(height: Spacing.lg),
                    Text('Amamentação na primeira hora?', style: textStyles.textStyle),
                    SizedBox(height: Spacing.sm),
                    _buildTabBar(breastfeedFirstHourEC, const ['Sim', 'Não', 'Não sei']),
                    SizedBox(height: Spacing.lg),
                    _buildSwitchTile(
                      'Restrições à amamentação?',
                      breastfeedRestrictions,
                      (v) => setState(() => breastfeedRestrictions = v),
                    ),
                    SizedBox(height: Spacing.lg),
                    Text('Primeiro banho do bebê por?', style: textStyles.textStyle),
                    SizedBox(height: Spacing.sm),
                    _buildTabBar(firstBathEC, const ['Profissional', 'Acompanhante', 'Eu', 'Não sei']),
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

  Widget _buildTabBar(TextEditingController controller, List<String> labels) {
    return Row(
      children: List.generate(labels.length, (index) {
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => controller.text = index.toString()),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: RadiusTokens.mdAll,
                border: Border.all(color: context.colors.darkText),
                color: controller.text == index.toString() ? context.colors.secondary : context.colors.surface,
                boxShadow: [ElevationTokens.subtleShadow(Theme.of(context).colorScheme.onSurface)],
              ),
              child: Text(labels[index], style: context.textStyles.caption, textAlign: TextAlign.center),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSwitchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: context.textStyles.textStyle),
      value: value,
      onChanged: onChanged,
      activeThumbColor: context.colors.text,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  SizedBox _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          _controller.saveBirth(
            Birth(
              id: _controller.birth?.id ?? 0,
              whoCut: WhoCutUmbilicalCord.values[_parseSafely(whoCutEC)],
              collectStemCells: collectStemCells,
              skinBabyContact: SkinBabyContact.values[_parseSafely(skinBabyContactEC)],
              breastfeedFirstHour: BreastfeedFirstHour.values[_parseSafely(breastfeedFirstHourEC)],
              breastfeedRestrictions: breastfeedRestrictions,
              firstBath: FirstBath.values[_parseSafely(firstBathEC)],
            ),
          );
        },
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Salvar'),
      ),
    );
  }
}
