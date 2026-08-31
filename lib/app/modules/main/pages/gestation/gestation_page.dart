import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../app_module.dart';
import '../../../../core/extensions/size_extension.dart';
import '../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../core/ui/theme/styles/design_tokens.dart';
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
      padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
      child: Observer(
        builder: (_) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: EdgeInsets.only(bottom: Spacing.sm),
            children: [
              PregnantCard(
                name: _controller.gestante?.nome,
                birthDate: _controller.gestante?.dataNascimento,
                lastMenstrualPeriod: _controller.gestacao?.dataUltimaMenstruacao,
                localPreNatal: _controller.gestacao?.localPreNatal,
                profissionalPreNatal: _controller.gestacao?.profissionalPreNatal,
                contatoLocalPreNatal: _controller.gestacao?.contatoLocalPreNatal,
                onEdit: () {
                  Modular.to.pushNamed(routeGravidezAtual).then((_) => _controller.initialize());
                },
              ),
              SizedBox(height: Spacing.sm),
              MaternityCard(
                prenatalPlace: _controller.gestacao?.localPreNatal,
                onEdit: () {
                  Modular.to.pushNamed(routeGravidezAtual).then((_) => _controller.initialize());
                },
              ),
              SizedBox(height: Spacing.sm),
              PrenatalAppointmentCard(
                list: _controller.appointments,
                onChanged: () => _controller.initialize(),
              ),
              SizedBox(height: Spacing.sm),
              BabyDataCard(
                list: _controller.exams,
                onChanged: () => _controller.initialize(),
              ),
              SizedBox(height: Spacing.sm),
              PregnancyHistoryCard(
                list: _controller.historyItems,
                onEdit: () async {
                  // `true` = o formulário salvou; recarrega só o histórico para
                  // refletir os novos valores sem trocar de aba (FASE 9J-PRE-FIX1).
                  final saved = await Modular.to.pushNamed(routeHistoria);
                  if (saved == true) {
                    _controller.refreshHistorico();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
