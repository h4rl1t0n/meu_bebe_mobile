import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../widgets/base_card.dart';
import 'observations_controller.dart';
import 'observations_form_controller.dart';

class ObservationsPage extends StatefulWidget {
  const ObservationsPage({super.key});

  @override
  State<ObservationsPage> createState() => _ObservationsPageState();
}

class _ObservationsPageState extends State<ObservationsPage> with ObservationsFormController {
  final _controller = Modular.get<ObservationsController>();

  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          initializeForm(_controller.plano);
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
          appBar: AppBar(
            title: Text('Observações', style: textStyles.titleSmallStyle),
            centerTitle: true,
          ),
          body: Container(
            padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
            child: SingleChildScrollView(
              child: BaseCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Observações e outros desejos', style: textStyles.titleSmallStyle),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: observationsEC,
                      maxLines: 10,
                      minLines: 5,
                      decoration: const InputDecoration(
                        label: Text('Descreva aqui suas observações e outros desejos para o parto'),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
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

  SizedBox _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          _controller.saveObservations(observacoes: observationsEC.text);
        },
        icon: const Icon(Icons.save, size: 18),
        label: const Text('Salvar'),
      ),
    );
  }
}
