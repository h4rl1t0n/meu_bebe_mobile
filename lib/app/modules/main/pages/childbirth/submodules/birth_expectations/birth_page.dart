import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Modular.to.pop();
          });
        }
        return Scaffold(
          appBar: AppBar(title: Text('Nascimento', style: textStyles.titleSmallStyle), centerTitle: true),
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: SingleChildScrollView(
              child: BaseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expectativas para o nascimento', style: textStyles.titleSmallStyle),
                    const SizedBox(height: 16),
                    Text('Quem cortará o cordão umbilical?', style: textStyles.textStyle),
                    const SizedBox(height: 8),
                    _buildTabBar(whoCutEC, const ['Profissional', 'Acompanhante', 'Eu', 'Não sei']),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      'Coleta de células-tronco?',
                      collectStemCells,
                      (v) => setState(() => collectStemCells = v),
                    ),
                    const SizedBox(height: 16),
                    Text('Contato pele a pele?', style: textStyles.textStyle),
                    const SizedBox(height: 8),
                    _buildTabBar(skinBabyContactEC, const ['Sim', 'Não', 'Não sei']),
                    const SizedBox(height: 16),
                    Text('Amamentação na primeira hora?', style: textStyles.textStyle),
                    const SizedBox(height: 8),
                    _buildTabBar(breastfeedFirstHourEC, const ['Sim', 'Não', 'Não sei']),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      'Restrições à amamentação?',
                      breastfeedRestrictions,
                      (v) => setState(() => breastfeedRestrictions = v),
                    ),
                    const SizedBox(height: 16),
                    Text('Primeiro banho do bebê por?', style: textStyles.textStyle),
                    const SizedBox(height: 8),
                    _buildTabBar(firstBathEC, const ['Profissional', 'Acompanhante', 'Eu', 'Não sei']),
                    const SizedBox(height: 24),
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
                borderRadius: _getBorderRadius(index, labels.length),
                border: Border.all(color: context.colors.darkText),
                color: controller.text == index.toString() ? context.colors.secondary : null,
              ),
              child: Text(labels[index], style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
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

  BorderRadiusGeometry? _getBorderRadius(int index, int total) {
    if (index == 0) return const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16));
    if (index == total - 1) {
      return const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16));
    }
    return null;
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
              whoCut: WhoCutUmbilicalCord.values[int.parse(whoCutEC.text)],
              collectStemCells: collectStemCells,
              skinBabyContact: SkinBabyContact.values[int.parse(skinBabyContactEC.text)],
              breastfeedFirstHour: BreastfeedFirstHour.values[int.parse(breastfeedFirstHourEC.text)],
              breastfeedRestrictions: breastfeedRestrictions,
              firstBath: FirstBath.values[int.parse(firstBathEC.text)],
            ),
          );
        },
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Salvar'),
      ),
    );
  }
}
