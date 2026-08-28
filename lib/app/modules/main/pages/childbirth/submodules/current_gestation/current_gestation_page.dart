import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/gestacao/gestacao_model.dart';
import '../../../../widgets/base_card.dart';
import 'current_gestation_controller.dart';
import 'current_gestation_form_controller.dart';

class CurrentGestationPage extends StatefulWidget {
  const CurrentGestationPage({super.key});

  @override
  State<CurrentGestationPage> createState() => _CurrentGestationPageState();
}

class _CurrentGestationPageState extends State<CurrentGestationPage>
    with CurrentGestationFormController {
  final formKey = GlobalKey<FormState>();
  final _controller = Modular.get<CurrentGestationController>();

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
        title: Text('Gravidez Atual', style: context.textStyles.titleSmallStyle),
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
                  'Sobre a minha gravidez',
                  style: context.textStyles.titleSmallStyle,
                ),
                SizedBox(height: Spacing.lg),
                _buildTextField(
                  lastMenstrualPeriodEC,
                  'Data da última menstruação',
                  validator: _validateDum,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    DataInputFormatter(),
                  ],
                ),
                SizedBox(height: Spacing.lg),
                _buildTextField(
                  localPreNatalEC,
                  'Local do pré-natal',
                  inputFormatters: [LengthLimitingTextInputFormatter(255)],
                ),
                SizedBox(height: Spacing.lg),
                _buildTextField(
                  profissionalPreNatalEC,
                  'Profissional do pré-natal',
                  inputFormatters: [LengthLimitingTextInputFormatter(255)],
                ),
                SizedBox(height: Spacing.lg),
                _buildTextField(
                  contatoLocalPreNatalEC,
                  'Contato do local',
                  inputFormatters: [LengthLimitingTextInputFormatter(64)],
                ),
                SizedBox(height: Spacing.lg),
                _saveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateDum(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (dumDisplayToIso(v) == null) return 'Informe uma data válida';
    return null;
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

    final dumText = lastMenstrualPeriodEC.text.trim();
    final dum = dumDisplayToIso(dumText);
    if (dumText.isNotEmpty && dum == null) return;

    final local = localPreNatalEC.text.trim();
    final profissional = profissionalPreNatalEC.text.trim();
    final contato = contatoLocalPreNatalEC.text.trim();

    final ok = await _controller.save(
      GestacaoModel(
        id: _controller.model?.id ?? '',
        dataUltimaMenstruacao: dum,
        localPreNatal: local.isEmpty ? null : local,
        profissionalPreNatal: profissional.isEmpty ? null : profissional,
        contatoLocalPreNatal: contato.isEmpty ? null : contato,
      ),
    );

    if (ok && mounted) {
      Navigator.pop(context);
    }
  }
}
