import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../app_module.dart';
import '../../../../core/extensions/size_extension.dart';
import '../../../../core/ui/theme/styles/colors_app.dart';
import 'gestation_controller.dart';
import 'submodules/baby_data/baby_data_card.dart';
import 'submodules/maternity/maternity_card.dart';
import 'submodules/pregnancy_history/pregnancy_history_card.dart';
import 'submodules/pregnant/pregnant_card.dart';
import 'submodules/prenatal_appointment/prenatal_appointment_card.dart';

class GestationPage extends StatefulWidget {
  const GestationPage({super.key});

  @override
  State<GestationPage> createState() => _GestationPageState();
}

class _GestationPageState extends State<GestationPage> {
  final _controller = Modular.get<GestationController>();

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.screenWidth,
      color: context.colors.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Observer(
        builder: (_) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              spacing: 16,
              children: [
                PregnantCard(
                  pregnantData: _controller.pregnantData,
                  currentPregnancy: _controller.currentPregnancyData,
                  onEdit: () {
                    Modular.to.pushNamed(routeIndetificacao).then((_) => _controller.initialize());
                  },
                ),
                MaternityCard(
                  prenatalPlace: _controller.pregnantData?.prenatalPlace,
                  onEdit: () {
                    Modular.to.pushNamed(routeIndetificacao).then((_) => _controller.initialize());
                  },
                ),
                const PrenatalAppointmentCard(list: []),
                const BabyDataCard(list: []),
                const PregnancyHistoryCard(list: []),
              ],
            ),
          );
        },
      ),
    );
  }
}
