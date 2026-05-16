import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/text_styles.dart';
import 'vaccines_controller.dart';
import 'widgets/vaccine_card.dart';

class VaccinesPage extends StatefulWidget {
  const VaccinesPage({super.key});

  @override
  State<VaccinesPage> createState() => _VaccinesPageState();
}

class _VaccinesPageState extends State<VaccinesPage> {
  final controller = Modular.get<VaccinesController>();

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
    final textStyles = context.textStyles;

    return FutureBuilder(
      future: controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: Text('Minhas Vacinas', style: textStyles.titleSmallStyle), centerTitle: true),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Observer(
                builder: (context) {
                  if (controller.vaccines.isEmpty) {
                    return Center(child: Text('Carregando as vacinas', style: textStyles.subTitleStyle));
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.center,
                          child: Text('Qualquer tempo', style: textStyles.titleSmallStyle),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: controller.vaccines
                              .where((vaccine) => vaccine.id < controller.vaccines.length - 1)
                              .map(
                                (vaccine) => VaccineCard(
                                  used: vaccine.used,
                                  onChanged: () {
                                    controller.updateVaccine(vaccine.copyWith(used: !vaccine.used));
                                  },
                                  index: vaccine.id,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 32),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            '20ª semana de gravidez até 45 dias após o parto',
                            textAlign: TextAlign.center,
                            style: textStyles.titleSmallStyle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (controller.vaccines.isNotEmpty)
                          VaccineCard(
                            used: controller.vaccines.last.used,
                            onChanged: () {
                              controller.updateVaccine(
                                controller.vaccines.last.copyWith(used: !controller.vaccines.last.used),
                              );
                            },
                            index: controller.vaccines.last.id,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
