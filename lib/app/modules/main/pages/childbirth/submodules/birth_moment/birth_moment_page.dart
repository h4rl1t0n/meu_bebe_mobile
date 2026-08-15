import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/birth_moment.dart';
import '../../../../widgets/base_card.dart';
import 'birth_moment_controller.dart';
import 'birth_moment_form_controller.dart';

class BirthMomentPage extends StatefulWidget {
  const BirthMomentPage({super.key});

  @override
  State<BirthMomentPage> createState() => _BirthMomentPageState();
}

class _BirthMomentPageState extends State<BirthMomentPage> with BirthMomentFormController {
  final formKey = GlobalKey<FormState>();
  final _controller = Modular.get<BirthMomentController>();

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
          initializeForm(_controller.birthMoment);
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
          appBar: AppBar(title: Text('Momento do Parto', style: textStyles.titleSmallStyle), centerTitle: true),
          body: Container(
            padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
            child: SingleChildScrollView(
              child: BaseCard(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Como você prefere ...', style: textStyles.titleSmallStyle),
                      SizedBox(height: Spacing.lg),
                      Text('Via de parto?', style: textStyles.textStyle),
                      SizedBox(height: Spacing.sm),
                      _buildTabBar(birthWayEC, const ['Vaginal', 'Cesárea', 'Não sei']),
                      SizedBox(height: Spacing.lg),
                      Text('Anestesia?', style: textStyles.textStyle),
                      SizedBox(height: Spacing.sm),
                      _buildTabBar(anesthesiaEC, const ['Sim', 'Não', 'Não sei']),
                      SizedBox(height: Spacing.lg),
                      Text('Corte vaginal (episiotomia)?', style: textStyles.textStyle),
                      SizedBox(height: Spacing.sm),
                      _buildTabBar(vaginalCutEC, const ['Sim', 'Não', 'Não sei']),
                      SizedBox(height: Spacing.lg),
                      Text('Posição preferida para o parto?', style: textStyles.textStyle),
                      SizedBox(height: Spacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPositionTab('Deitada', 0),
                          _buildPositionTab('Sentada', 1),
                          _buildPositionTab('Agachada', 2),
                          _buildPositionTab('De lado', 3),
                          _buildPositionTab('De joelhos', 4),
                          _buildPositionTab('Em pé', 5),
                          _buildPositionTab('Não sei', 6),
                          _buildPositionTab('Outra', 7),
                        ],
                      ),
                      Observer(
                        builder: (_) {
                          if (preferredPositionEC.text == '7') {
                            return Padding(
                              padding: EdgeInsets.only(top: Spacing.md),
                              child: TextFormField(
                                controller: otherPositionEC,
                                decoration: const InputDecoration(
                                  label: Text('Descreva a posição'),
                                  border: OutlineInputBorder(),
                                ),
                              ),
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
          ),
        );
      },
    );
  }

  Widget _buildTabBar(TextEditingController controller, List<String> labels) {
    return Row(
      spacing: 5,
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

  Widget _buildPositionTab(String label, int index) {
    return InkWell(
      onTap: () => setState(() => preferredPositionEC.text = index.toString()),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
        decoration: BoxDecoration(
          borderRadius: RadiusTokens.lgAll,
          border: Border.all(color: context.colors.darkText),
          color: preferredPositionEC.text == index.toString() ? context.colors.secondary : context.colors.surface,
        ),
        child: Text(label, style: context.textStyles.caption),
      ),
    );
  }

  SizedBox _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          FocusScope.of(context).unfocus();
          _controller.saveBirthMoment(
            BirthMoment(
              id: _controller.birthMoment?.id ?? 0,
              birthWay: BirthWay.values[_parseSafely(birthWayEC)],
              anesthesia: Anesthesia.values[_parseSafely(anesthesiaEC)],
              vaginalCut: VaginalCut.values[_parseSafely(vaginalCutEC)],
              preferredPosition: preferredPositionEC.text.isNotEmpty
                  ? Positions.values[_parseSafely(preferredPositionEC)]
                  : null,
              otherPosition: otherPositionEC.text.isNotEmpty ? otherPositionEC.text : null,
            ),
          );
        },
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Salvar'),
      ),
    );
  }
}
