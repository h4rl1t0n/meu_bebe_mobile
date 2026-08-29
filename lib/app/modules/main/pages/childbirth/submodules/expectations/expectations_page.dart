import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../widgets/base_card.dart';
import 'expectations_controller.dart';
import 'expectations_form_controller.dart';

class ExpectationsPage extends StatefulWidget {
  const ExpectationsPage({super.key});

  @override
  State<ExpectationsPage> createState() => _ExpectationsPageState();
}

class _ExpectationsPageState extends State<ExpectationsPage> with ExpectationsFormController {
  final formKey = GlobalKey<FormState>();
  final _controller = Modular.get<ExpectationsController>();
  late ReactionDisposer _reactionDisposer;

  @override
  void initState() {
    super.initState();
    // O formulário mantém o estado de seleção em `TextEditingController.text`
    // (não-observável). Para que os dados persistidos apareçam SEM interação do
    // usuário, re-hidratamos o formulário sempre que o `plano` (observable) do
    // controller mudar — tipicamente ao final do `initialize()`.
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
          appBar: AppBar(
            title: Text('Expectativas para o Parto', style: textStyles.titleSmallStyle),
            centerTitle: true,
          ),
          body: Container(
            padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
            child: SingleChildScrollView(
              child: BaseCard(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Text('Você gostaria de ...', style: textStyles.titleSmallStyle),
                      SizedBox(height: Spacing.lg),
                      Text('Ter um acompanhante?', style: textStyles.textStyle),
                      _customTabBar(companionEC),
                      SizedBox(height: Spacing.sm),
                      Text('Raspar os pelos íntimos?', style: textStyles.textStyle),
                      _customTabBar(shaveIntimateHairEC),
                      SizedBox(height: Spacing.sm),
                      Text('Fazer lavagem intestinal?', style: textStyles.textStyle),
                      _customTabBar(bowelWashOrSuppositoryEC),
                      SizedBox(height: Spacing.sm),
                      Text('Ter um ambiente com pouca luminosidade?', style: textStyles.textStyle),
                      _customTabBar(lowLightEnvironmentEC),
                      SizedBox(height: Spacing.sm),
                      Text('Ouvir música?', style: textStyles.textStyle),
                      _customTabBar(listenToMusicEC),
                      SizedBox(height: Spacing.sm),
                      Text('Beber líquidos', style: textStyles.textStyle),
                      _customTabBar(drinkLiquidsEC),
                      SizedBox(height: Spacing.sm),
                      Text('Registar com fotos ou filmagens?', style: textStyles.textStyle),
                      _customTabBar(recordPhotosOrVideosEC),
                      SizedBox(height: Spacing.lg),
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

  Widget _customTabBar(TextEditingController controllerEC) {
    return Row(
      spacing: 5,
      children: [
        _tab(TriState.sim.label, TriState.sim, controllerEC),
        _tab(TriState.nao.label, TriState.nao, controllerEC),
        _tab(TriState.naoSei.label, TriState.naoSei, controllerEC),
      ],
    );
  }

  Widget _tab(String content, TriState value, TextEditingController controllerEC) {
    return Expanded(
      child: InkWell(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: RadiusTokens.mdAll,
            border: Border.all(color: context.colors.darkText),
            color: controllerEC.text == value.value ? context.colors.secondary : context.colors.surface,
            boxShadow: [ElevationTokens.subtleShadow(Theme.of(context).colorScheme.onSurface)],
          ),
          child: Center(child: Text(content)),
        ),
        onTap: () {
          setState(() {
            controllerEC.text = value.value;
          });
        },
      ),
    );
  }

  SizedBox _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          FocusScope.of(context).unfocus();
          final valid = formKey.currentState?.validate() ?? false;
          if (valid) {
            _controller.saveExpectations(
              acompanhante: triState(companionEC),
              rasparPelosIntimos: triState(shaveIntimateHairEC),
              lavagemIntestinal: triState(bowelWashOrSuppositoryEC),
              ambientePoucaLuz: triState(lowLightEnvironmentEC),
              ouvirMusica: triState(listenToMusicEC),
              beberLiquidos: triState(drinkLiquidsEC),
              registrarFotosVideos: triState(recordPhotosOrVideosEC),
            );
          }
        },
        child: const Text('Salvar'),
      ),
    );
  }
}
