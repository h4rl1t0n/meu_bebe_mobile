import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:validatorless/validatorless.dart';

import '../../../../../../core/helpers/civil_date.dart';
import '../../../../../../core/helpers/messages.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../widgets/base_card.dart';
import 'identification_controller.dart';
import 'identification_form_controller.dart';

class IdentificationPage extends StatefulWidget {
  const IdentificationPage({super.key});

  @override
  State<IdentificationPage> createState() => _IdentificationPageState();
}

class _IdentificationPageState extends State<IdentificationPage> with IdentificationFormController {
  final formKey = GlobalKey<FormState>();
  final _controller = Modular.get<IdentificationController>();

  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      initializeForm(_controller.gestante, _controller.gestacao);
    });
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (_controller.saved) {
          _controller.setSaved(false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Modular.to.pop();
          });
        }
        return Scaffold(appBar: _buildAppBar, body: _buildBody);
      },
    );
  }

  AppBar get _buildAppBar {
    return AppBar(title: Text('Gestante', style: context.textStyles.titleSmallStyle), centerTitle: true);
  }

  Widget get _buildBody {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
      child: SingleChildScrollView(
        child: BaseCard(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Text('Dados da Gestante', style: context.textStyles.titleSmallStyle),
                SizedBox(height: Spacing.sm),
                _buildTextField(
                  nameEC,
                  'Nome',
                  validator: Validatorless.required('Nome obrigatório'),
                  captalization: TextCapitalization.words,
                ),
                const SizedBox(height: Spacing.sm),
                _buildTextField(socialNameEC, 'Nome social', captalization: TextCapitalization.words),
                const SizedBox(height: Spacing.sm),
                _buildTextField(
                  birthdayEC,
                  'Data de nascimento',
                  validator: Validatorless.required('Data de nascimento obrigatória'),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, DataInputFormatter()],
                ),
                const SizedBox(height: Spacing.sm),
                _buildTextField(
                  cpfEC,
                  'CPF',
                  validator: Validatorless.required('CPF obrigatório'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()],
                ),
                const SizedBox(height: Spacing.sm),
                _buildTextField(
                  nationalHealthCardEC,
                  'Número do Cartão Nacional de Saúde',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: Spacing.sm),
                _buildTextField(prenatalPlaceEC, 'Local que realiza o pré-natal'),
                const SizedBox(height: Spacing.sm),
                _buildTextField(profissionalEC, 'Nome do profissional', captalization: TextCapitalization.words),
                const SizedBox(height: Spacing.sm),
                _buildTextField(
                  prenatalPlaceContactEC,
                  'Contato do local',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, TelefoneInputFormatter()],
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

  SizedBox _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          FocusScope.of(context).unfocus();
          final valid = formKey.currentState?.validate() ?? false;
          if (!valid) return;

          final isoDate = civilDateDisplayToIso(birthdayEC.text);
          if (isoDate == null) {
            Messages.showError('Data de nascimento inválida.');
            return;
          }

          final socialName = socialNameEC.text.trim();
          final cpf = digitsOnly(cpfEC.text);
          final cns = digitsOnly(nationalHealthCardEC.text);
          final local = prenatalPlaceEC.text.trim();
          final profissional = profissionalEC.text.trim();
          final contato = prenatalPlaceContactEC.text.trim();

          _controller.saveIdentification(
            nome: nameEC.text.trim(),
            nomeSocial: socialName.isEmpty ? null : socialName,
            dataNascimento: isoDate,
            cpf: cpf.isEmpty ? null : cpf,
            cns: cns.isEmpty ? null : cns,
            localPreNatal: local.isEmpty ? null : local,
            profissionalPreNatal: profissional.isEmpty ? null : profissional,
            contatoLocalPreNatal: contato.isEmpty ? null : contato,
          );
        },
        child: const Text('Salvar'),
      ),
    );
  }
}
