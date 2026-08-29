import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
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
          appBar: AppBar(title: Text('Alívio da Dor', style: textStyles.titleSmallStyle), centerTitle: true),
          body: Container(
            padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
            child: SingleChildScrollView(
              child: BaseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deseja medidas para alívio da dor?', style: textStyles.titleSmallStyle),
                    SizedBox(height: Spacing.md),
                    _buildTabBar(),
                    Observer(
                      builder: (_) {
                        if (painReliefEC.text == TriState.sim.value) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: Spacing.xl),
                              Text('Quais métodos você prefere?', style: textStyles.titleSmallStyle),
                              SizedBox(height: Spacing.sm),
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

  Widget _buildTabBar() {
    return Row(
      children: TriState.values.map((v) {
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => painReliefEC.text = v.value),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: RadiusTokens.mdAll,
                border: Border.all(color: context.colors.darkText),
                color: painReliefEC.text == v.value ? context.colors.secondary : context.colors.surface,
                boxShadow: [ElevationTokens.subtleShadow(Theme.of(context).colorScheme.onSurface)],
              ),
              child: Text(v.label, textAlign: TextAlign.center),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Material(
      color: Colors.transparent,
      child: CheckboxListTile(
        title: Text(label, style: context.textStyles.textStyle),
        value: value,
        onChanged: onChanged,
        activeColor: context.colors.text,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
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
          _controller.savePainRelief(
            querAlivioDor: triState(),
            massagem: massage,
            exerciciosBola: ballExercises,
            exerciciosRespiracao: breathRelaxExercises,
            banhoChuveiro: showerBath,
            banhoBanheira: bathtubBath,
            acupuntura: acupuncture,
            acupressao: acupressure,
            outroMetodo: otherMethod,
          );
        },
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Salvar'),
      ),
    );
  }
}
