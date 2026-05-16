import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.updated) {
        controller.resetUpdated();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Meus Medicamentos', style: context.textStyles.titleSmallStyle),
              centerTitle: true,
            ),
            body: _buildBody,
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget get _buildBody => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
    child: Observer(
      builder: (_) => Visibility(
        visible: !controller.updated,
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
            const SizedBox(height: 16),
            controller.medications.isNotEmpty
                ? Expanded(
                    child: ListView(
                      children: controller.medications
                          .map(
                            (medication) => MedicineCard(
                              name: medication.name,
                              dose: medication.dose,
                              medicineTime: medication.medicationTime,
                              onTap: () {
                                controller.deleteMedication(medication.id);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  )
                : const Expanded(
                    child: SizedBox(child: Center(child: Text('Não foram encontrados medicamentos'))),
                  ),
          ],
        ),
      ),
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
