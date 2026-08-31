import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/historico_obstetrico/historico_obstetrico_model.dart';
import '../../../../widgets/base_card.dart';
import 'history_controller.dart';
import 'history_form_controller.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with HistoryFormController {
  final formKey = GlobalKey<FormState>();
  final _controller = Modular.get<HistoryController>();

  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      if (mounted) initializeForm(_controller.model);
    });
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestações Anteriores',
          style: context.textStyles.titleSmallStyle,
        ),
        centerTitle: true,
      ),
      body: Observer(
        builder: (_) {
          if (_controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBody;
        },
      ),
    );
  }

  Widget get _buildBody {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Spacing.pageH,
        vertical: Spacing.pageV,
      ),
      child: SingleChildScrollView(
        child: BaseCard(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'História das gestações anteriores',
                  style: context.textStyles.titleSmallStyle,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  pregnantNumberEC,
                  'Número de vezes que já ficou grávida',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  childbirthNumberEC,
                  'Número de vezes que já teve parto',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  abortionNumberEC,
                  'Número de abortos que já teve',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                _saveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label, {
    FormFieldValidator<String?>? validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization captalization = TextCapitalization.sentences,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(label: Text(label)),
      keyboardType: keyboardType,
      textCapitalization: captalization,
      inputFormatters: inputFormatters,
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _controller.loading ? null : _handleSave,
        child: const Text('Salvar'),
      ),
    );
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    final valid = formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final ok = await _controller.save(
      HistoricoObstetricoModel(
        id: _controller.model?.id ?? '',
        pregnancyNumber: _parseCount(pregnantNumberEC),
        givenBirthNumber: _parseCount(childbirthNumberEC),
        abortionsNumber: _parseCount(abortionNumberEC),
      ),
    );

    if (ok && mounted) {
      // Retorna `true` para a aba Gestação poder detectar que houve SAVE e
      // recarregar o histórico imediatamente (FASE 9J-PRE-FIX1).
      Navigator.pop(context, true);
    }
  }

  int? _parseCount(TextEditingController controller) {
    final t = controller.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }
}
