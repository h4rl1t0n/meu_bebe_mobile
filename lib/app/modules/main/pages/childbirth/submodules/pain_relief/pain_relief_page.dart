import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../formulario/widgets/dss_question.dart';
import 'pain_relief_controller.dart';

class PainReliefPage extends StatefulWidget {
  const PainReliefPage({super.key});

  @override
  State<PainReliefPage> createState() => _PainReliefPageState();
}

class _PainReliefPageState extends State<PainReliefPage> {
  final _controller = Modular.get<PainReliefController>();

  @override
  void initState() {
    super.initState();
    _controller.initialize();
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
              child: DssQuestionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deseja medidas para alívio da dor?',
                      style: textStyles.textStyle.copyWith(color: Colors.black),
                    ),
                    SizedBox(height: Spacing.md),
                    _buildTabBar(_controller.querAlivioDor, _controller.setQuerAlivioDor),
                    if (_controller.querAlivioDor == TriState.sim)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: Spacing.xl),
                          Text('Quais métodos você prefere?', style: textStyles.titleSmallStyle),
                          SizedBox(height: Spacing.sm),
                          _buildCheckbox('Massagem', _controller.massagem, _controller.setMassagem),
                          _buildCheckbox(
                            'Exercícios com bola',
                            _controller.exerciciosBola,
                            _controller.setExerciciosBola,
                          ),
                          _buildCheckbox(
                            'Respiração e relaxamento',
                            _controller.exerciciosRespiracao,
                            _controller.setExerciciosRespiracao,
                          ),
                          _buildCheckbox('Banho de chuveiro', _controller.banhoChuveiro, _controller.setBanhoChuveiro),
                          _buildCheckbox('Banho de banheira', _controller.banhoBanheira, _controller.setBanhoBanheira),
                          _buildCheckbox('Acupuntura', _controller.acupuntura, _controller.setAcupuntura),
                          _buildCheckbox('Acupressão', _controller.acupressao, _controller.setAcupressao),
                          _buildCheckbox('Outro método', _controller.outroMetodo, _controller.setOutroMetodo),
                        ],
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

  Widget _buildTabBar(TriState selected, ValueChanged<TriState> onSelect) {
    return Row(
      spacing: 5,
      children: TriState.values.map((v) {
        return Expanded(
          child: InkWell(
            onTap: () => onSelect(v),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: RadiusTokens.mdAll,
                border: Border.all(color: context.colors.darkText),
                color: selected == v ? context.colors.secondary : context.colors.surface,
                boxShadow: [ElevationTokens.subtleShadow(Theme.of(context).colorScheme.onSurface)],
              ),
              child: Text(v.label, textAlign: TextAlign.center),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool> onChanged) {
    return Material(
      color: Colors.transparent,
      child: CheckboxListTile(
        title: Text(label, style: context.textStyles.textStyle),
        value: value,
        onChanged: (v) => onChanged(v ?? false),
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
        onPressed: _controller.savePainRelief,
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Salvar'),
      ),
    );
  }
}
