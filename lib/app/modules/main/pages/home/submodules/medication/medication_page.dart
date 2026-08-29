import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import 'medication_controller.dart';
import 'widgets/medication_dialog.dart';
import 'widgets/medicine_card.dart';

class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  final controller = Modular.get<MedicationController>();
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Medicamentos', style: context.textStyles.titleSmallStyle),
        centerTitle: true,
      ),
      body: Observer(
        builder: (_) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!controller.hasGestacao) {
            return Center(
              child: Text(
                'Cadastre sua gestação para gerenciar medicamentos.',
                textAlign: TextAlign.center,
                style: context.textStyles.subTitleStyle,
              ),
            );
          }
          return _buildBody;
        },
      ),
    );
  }

  Widget get _buildBody => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Spacing.pageH,
      vertical: Spacing.pageV,
    ),
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => openAddMedicationDialog(),
            child: const Text('Adicionar medicamento'),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        controller.medications.isNotEmpty
            ? Expanded(
                child: ListView(
                  children: controller.medications
                      .map(
                        (medication) => MedicineCard(
                          name: medication.nome,
                          dose: medication.dose,
                          frequencia: medication.frequencia,
                          onTap: () {
                            controller.deleteMedication(medication.id);
                          },
                        ),
                      )
                      .toList(),
                ),
              )
            : const Expanded(
                child: SizedBox(
                  child: Center(child: Text('Não foram encontrados medicamentos')),
                ),
              ),
      ],
    ),
  );

  void openAddMedicationDialog() {
    showDialog(
      context: context,
      builder: (context) => Form(
        key: formKey,
        child: MedicationDialog(formKey: formKey, controller: controller),
      ),
    );
  }
}
