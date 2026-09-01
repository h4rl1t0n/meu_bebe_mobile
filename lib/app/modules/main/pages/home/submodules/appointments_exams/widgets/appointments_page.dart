import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../../../../core/helpers/civil_date.dart';
import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../appointments_exams_controller.dart';
import 'card_with_date.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key, required this.controller});

  final AppointmentsExamsController controller;

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  AppointmentsExamsController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
      child: Observer(
        builder: (_) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_controller.hasGestacao) {
            return Center(
              child: Text(
                'Cadastre sua gestação para gerenciar consultas e exames.',
                textAlign: TextAlign.center,
                style: context.textStyles.subTitleStyle,
              ),
            );
          }
          return Column(
            children: [
              const SizedBox(height: Spacing.lg),
              _controller.appointments.isNotEmpty
                  ? Expanded(
                      child: ListView(
                        children: _controller.appointments
                            .map(
                              (appointment) => CardWithDate(
                                title: appointment.titulo,
                                date: civilDateIsoToDisplay(appointment.dataConsulta),
                                description: appointment.descricao,
                                onTap: () {
                                  _controller.deleteAppointment(appointment.id);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : Expanded(
                      child: SizedBox(
                        child: Center(
                          child: Text(
                            'Não foram encontradas consultas',
                            style: TextStyle(color: context.colors.darkText),
                          ),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
