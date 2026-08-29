import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
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
                      _buildViaPartoTabBar(),
                      SizedBox(height: Spacing.lg),
                      Text('Anestesia?', style: textStyles.textStyle),
                      SizedBox(height: Spacing.sm),
                      _buildTriTabBar(anesthesiaEC),
                      SizedBox(height: Spacing.lg),
                      Text('Corte vaginal (episiotomia)?', style: textStyles.textStyle),
                      SizedBox(height: Spacing.sm),
                      _buildTriTabBar(vaginalCutEC),
                      SizedBox(height: Spacing.lg),
                      Text('Posição preferida para o parto?', style: textStyles.textStyle),
                      SizedBox(height: Spacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PosicaoParto.values
                            .map((p) => _buildPositionTab(p.label, p.value))
                            .toList(),
                      ),
                      Observer(
                        builder: (_) {
                          if (preferredPositionEC.text == PosicaoParto.outra.value) {
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

  Widget _buildViaPartoTabBar() {
    return Row(
      spacing: 5,
      children: ViaParto.values.map((v) {
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => birthWayEC.text = v.value),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: RadiusTokens.mdAll,
                border: Border.all(color: context.colors.darkText),
                color: birthWayEC.text == v.value ? context.colors.secondary : context.colors.surface,
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

  Widget _buildPositionTab(String label, String value) {
    return InkWell(
      onTap: () => setState(() => preferredPositionEC.text = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
        decoration: BoxDecoration(
          borderRadius: RadiusTokens.lgAll,
          border: Border.all(color: context.colors.darkText),
          color: preferredPositionEC.text == value ? context.colors.secondary : context.colors.surface,
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
          final isOutra = preferredPositionEC.text == PosicaoParto.outra.value;
          _controller.saveBirthMoment(
            viaParto: viaParto(),
            anestesia: triState(anesthesiaEC),
            corteVaginal: triState(vaginalCutEC),
            posicaoPreferida: position(),
            outraPosicao: isOutra && otherPositionEC.text.trim().isNotEmpty
                ? otherPositionEC.text.trim()
                : null,
          );
        },
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Salvar'),
      ),
    );
  }
}
