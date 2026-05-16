import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/expectation.dart';
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

  List<int> selectedIndex = [];

  @override
  void initState() {
    super.initState();

    _controller.initialize().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          initializeForm(_controller.expectations);
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
          appBar: AppBar(
            title: Text('Expectativas para o Parto', style: textStyles.titleSmallStyle),
            centerTitle: true,
          ),
          body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: SingleChildScrollView(
              child: BaseCard(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Text('Você gostaria de ...', style: textStyles.titleSmallStyle),
                      SizedBox(height: 16),
                      Text('Ter um acompanhante?', style: textStyles.textStyle),
                      _customTabBar(companionEC),
                      SizedBox(height: 10),
                      Text('Raspar os pelos íntimos?', style: textStyles.textStyle),
                      _customTabBar(shaveIntimateHairEC),
                      SizedBox(height: 10),
                      Text('Fazer lavagem intestinal?', style: textStyles.textStyle),
                      _customTabBar(bowelWashOrSuppositoryEC),
                      SizedBox(height: 10),
                      Text('Ter um ambiente com pouca luminosidade?', style: textStyles.textStyle),
                      _customTabBar(lowLightEnvironmentEC),
                      SizedBox(height: 10),
                      Text('Ouvir música?', style: textStyles.textStyle),
                      _customTabBar(listenToMusicEC),
                      SizedBox(height: 10),
                      Text('Beber líquidos', style: textStyles.textStyle),
                      _customTabBar(drinkLiquidsEC),
                      SizedBox(height: 10),
                      Text('Registar com fotos ou filmagens?', style: textStyles.textStyle),
                      _customTabBar(recordPhotosOrVideosEC),
                      SizedBox(height: 16),
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
    log('Controlador: ${controllerEC.text}');
    return Row(
      children: [_tab('Sim', 0, controllerEC), _tab('Não', 1, controllerEC), _tab('Não sei', 2, controllerEC)],
    );
  }

  Widget _tab(String content, int index, TextEditingController controllerEC) {
    return Expanded(
      child: InkWell(
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: _getBorderRadius(index),
            border: Border.all(color: context.colors.darkText),
            color: controllerEC.text == index.toString() ? context.colors.secondary : null,
          ),
          child: Center(child: Text(content)),
        ),
        onTap: () {
          setState(() {
            controllerEC.text = index.toString();
          });
        },
      ),
    );
  }

  BorderRadiusGeometry? _getBorderRadius(int index) {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16));
      case 1:
        return null;
      case 2:
        return const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16));
    }

    return null;
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
            log('Tá aqui');
            _controller.saveExpectations(
              Expectation(
                id: 1,
                companion: Alternatives.values[int.parse(companionEC.text)],
                shaveIntimateHair: Alternatives.values[int.parse(shaveIntimateHairEC.text)],
                bowelWashOrSuppository: Alternatives.values[int.parse(bowelWashOrSuppositoryEC.text)],
                lowLightEnvironment: Alternatives.values[int.parse(lowLightEnvironmentEC.text)],
                listenToMusic: Alternatives.values[int.parse(listenToMusicEC.text)],
                drinkLiquids: Alternatives.values[int.parse(drinkLiquidsEC.text)],
                recordPhotosOrVideos: Alternatives.values[int.parse(recordPhotosOrVideosEC.text)],
              ),
            );
          }
        },
        child: const Text('Salvar'),
      ),
    );
  }
}
