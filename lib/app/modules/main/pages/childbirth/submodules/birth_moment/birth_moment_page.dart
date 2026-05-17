import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: SingleChildScrollView(
              child: BaseCard(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Como você prefere ...', style: textStyles.titleSmallStyle),
                      const SizedBox(height: 16),
                      Text('Via de parto?', style: textStyles.textStyle),
                      const SizedBox(height: 8),
                      _buildTabBar(birthWayEC, const ['Vaginal', 'Cesárea', 'Não sei']),
                      const SizedBox(height: 16),
                      Text('Anestesia?', style: textStyles.textStyle),
                      const SizedBox(height: 8),
                      _buildTabBar(anesthesiaEC, const ['Sim', 'Não', 'Não sei']),
                      const SizedBox(height: 16),
                      Text('Corte vaginal (episiotomia)?', style: textStyles.textStyle),
                      const SizedBox(height: 8),
                      _buildTabBar(vaginalCutEC, const ['Sim', 'Não', 'Não sei']),
                      const SizedBox(height: 16),
                      Text('Posição preferida para o parto?', style: textStyles.textStyle),
                      const SizedBox(height: 8),
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
                              padding: const EdgeInsets.only(top: 12),
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
                      const SizedBox(height: 24),
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
              child: Text(labels[index], style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.darkText),
          color: preferredPositionEC.text == index.toString() ? context.colors.secondary : null,
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
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
