import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../widgets/base_card.dart';
import 'expectations_controller.dart';

class ExpectationsPage extends StatefulWidget {
  const ExpectationsPage({super.key});

  @override
  State<ExpectationsPage> createState() => _ExpectationsPageState();
}

class _ExpectationsPageState extends State<ExpectationsPage> {
  final formKey = GlobalKey<FormState>();
  final _controller = Modular.get<ExpectationsController>();

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
                      _customTabBar(_controller.acompanhante, _controller.setAcompanhante),
                      SizedBox(height: Spacing.sm),
                      Text('Raspar os pelos íntimos?', style: textStyles.textStyle),
                      _customTabBar(_controller.rasparPelosIntimos, _controller.setRasparPelosIntimos),
                      SizedBox(height: Spacing.sm),
                      Text('Fazer lavagem intestinal?', style: textStyles.textStyle),
                      _customTabBar(_controller.lavagemIntestinal, _controller.setLavagemIntestinal),
                      SizedBox(height: Spacing.sm),
                      Text('Ter um ambiente com pouca luminosidade?', style: textStyles.textStyle),
                      _customTabBar(_controller.ambientePoucaLuz, _controller.setAmbientePoucaLuz),
                      SizedBox(height: Spacing.sm),
                      Text('Ouvir música?', style: textStyles.textStyle),
                      _customTabBar(_controller.ouvirMusica, _controller.setOuvirMusica),
                      SizedBox(height: Spacing.sm),
                      Text('Beber líquidos', style: textStyles.textStyle),
                      _customTabBar(_controller.beberLiquidos, _controller.setBeberLiquidos),
                      SizedBox(height: Spacing.sm),
                      Text('Registar com fotos ou filmagens?', style: textStyles.textStyle),
                      _customTabBar(_controller.registrarFotosVideos, _controller.setRegistrarFotosVideos),
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

  Widget _customTabBar(TriState selected, ValueChanged<TriState> onSelect) {
    return Row(
      spacing: 5,
      children: [
        _tab(TriState.sim.label, TriState.sim, selected, onSelect),
        _tab(TriState.nao.label, TriState.nao, selected, onSelect),
        _tab(TriState.naoSei.label, TriState.naoSei, selected, onSelect),
      ],
    );
  }

  Widget _tab(String content, TriState value, TriState selected, ValueChanged<TriState> onSelect) {
    return Expanded(
      child: InkWell(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: RadiusTokens.mdAll,
            border: Border.all(color: context.colors.darkText),
            color: selected == value ? context.colors.secondary : context.colors.surface,
            boxShadow: [ElevationTokens.subtleShadow(Theme.of(context).colorScheme.onSurface)],
          ),
          child: Center(child: Text(content)),
        ),
        onTap: () => onSelect(value),
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
            _controller.saveExpectations();
          }
        },
        child: const Text('Salvar'),
      ),
    );
  }
}
