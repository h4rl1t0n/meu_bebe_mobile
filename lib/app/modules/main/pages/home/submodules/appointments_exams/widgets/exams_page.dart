import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../../../../core/helpers/civil_date.dart';
import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';
import '../appointments_exams_controller.dart';
import 'card_with_date.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key, required this.controller});

  final AppointmentsExamsController controller;

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
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
              _controller.exams.isNotEmpty
                  ? Expanded(
                      child: ListView(
                        children: _controller.exams
                            .map(
                              (exam) => CardWithDate(
                                title: exam.titulo,
                                date: civilDateIsoToDisplay(exam.dataExame),
                                description: exam.descricao,
                                onTap: () {
                                  _controller.deleteExam(exam.id);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : Expanded(
                      child: SizedBox(
                        child: Center(
                          child: Text('Não foram encontrados exames', style: TextStyle(color: context.colors.darkText)),
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
