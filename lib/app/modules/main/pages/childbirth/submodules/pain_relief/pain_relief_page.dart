import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/pain_relief.dart';
import '../../../../widgets/base_card.dart';
import 'pain_relief_controller.dart';
import 'pain_relief_form_controller.dart';

class PainReliefPage extends StatefulWidget {
  const PainReliefPage({super.key});

  @override
  State<PainReliefPage> createState() => _PainReliefPageState();
}

class _PainReliefPageState extends State<PainReliefPage> with PainReliefFormController {
  final _controller = Modular.get<PainReliefController>();

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
          initializeForm(_controller.painRelief);
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
          appBar: AppBar(title: Text('Alívio da Dor', style: textStyles.titleSmallStyle), centerTitle: true),
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: SingleChildScrollView(
              child: BaseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deseja medidas para alívio da dor?', style: textStyles.titleSmallStyle),
                    const SizedBox(height: 12),
                    _buildTabBar(painReliefEC, const ['Sim', 'Não', 'Não sei']),
                    Observer(
                      builder: (_) {
                        if (painReliefEC.text == '0') {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Text('Quais métodos você prefere?', style: textStyles.titleSmallStyle),
                              const SizedBox(height: 8),
                              _buildCheckbox('Massagem', massage, (v) => setState(() => massage = v ?? false)),
                              _buildCheckbox(
                                'Exercícios com bola',
                                ballExercises,
                                (v) => setState(() => ballExercises = v ?? false),
                              ),
                              _buildCheckbox(
                                'Respiração e relaxamento',
                                breathRelaxExercises,
                                (v) => setState(() => breathRelaxExercises = v ?? false),
                              ),
                              _buildCheckbox(
                                'Banho de chuveiro',
                                showerBath,
                                (v) => setState(() => showerBath = v ?? false),
                              ),
                              _buildCheckbox(
                                'Banho de banheira',
                                bathtubBath,
                                (v) => setState(() => bathtubBath = v ?? false),
                              ),
                              _buildCheckbox(
                                'Acupuntura',
                                acupuncture,
                                (v) => setState(() => acupuncture = v ?? false),
                              ),
                              _buildCheckbox(
                                'Acupressão',
                                acupressure,
                                (v) => setState(() => acupressure = v ?? false),
                              ),
                              _buildCheckbox(
                                'Outro método',
                                otherMethod,
                                (v) => setState(() => otherMethod = v ?? false),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
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
              child: Text(labels[index], textAlign: TextAlign.center),
            ),
          ),
        );
      }),
    );
  }

  BorderRadiusGeometry? _getBorderRadius(int index, int total) {
    if (index == 0) return const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16));
    if (index == total - 1) {
      return const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16));
    }
    return null;
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label, style: context.textStyles.textStyle),
      value: value,
      onChanged: onChanged,
      activeColor: context.colors.text,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }

  SizedBox _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          _controller.savePainRelief(
            PainRelief(
              id: _controller.painRelief?.id ?? 0,
              painRelief: NeedPainRelief.values[_parseSafely(painReliefEC)],
              massage: massage,
              ballExercises: ballExercises,
              breathRelaxExercises: breathRelaxExercises,
              showerBath: showerBath,
              bathtubBath: bathtubBath,
              acupuncture: acupuncture,
              acupressure: acupressure,
              otherMethod: otherMethod,
            ),
          );
        },
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Salvar'),
      ),
    );
  }
}
