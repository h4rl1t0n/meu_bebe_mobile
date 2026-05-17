import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../app_module.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../birth_expectations/birth_expectations_card.dart';
import '../birth_moment/birth_moment_card.dart';
import '../current_gestation/widgets/current_gestation_card.dart';
import '../desires_expectations/desires_expectations_card.dart';
import '../expectations/widgets/expectations_card.dart';
import '../history/widgets/history_card.dart';
import '../identification/widgets/identification_card.dart';
import '../pain_relief/widgets/pain_relief_card.dart';
import 'childbirth_resume_controller.dart';

class ChildbirthResumePage extends StatefulWidget {
  const ChildbirthResumePage({super.key});

  @override
  State<ChildbirthResumePage> createState() => _ChildbirthResumePageState();
}

class _ChildbirthResumePageState extends State<ChildbirthResumePage> {
  final _controller = Modular.get<ChildbirthResumeController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (_controller.updated) {
        await _controller.initialize().then((value) => _controller.setUpdated(false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar, body: _buildBody);
  }

  AppBar get _buildAppBar {
    return AppBar(
      title: Text('Plano de parto detalhado', style: context.textStyles.titleSmallStyle),
      centerTitle: true,
    );
  }

  Widget get _buildBody {
    return FutureBuilder(
      future: _controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Observer(
            builder: (_) => Visibility(
              visible: !_controller.updated,
              replacement: const Center(child: CircularProgressIndicator()),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      IdentificationCard(
                        pregnantData: _controller.pregnantData,
                        onEdit: () =>
                            Modular.to.pushNamed(routeIndetificacao).then((_) => _controller.setUpdated(true)),
                      ),
                      SizedBox(height: Spacing.sm),
                      HistoryCard(
                        history: _controller.historyData,
                        onEdit: () => Modular.to.pushNamed(routeHistoria).then((_) => _controller.setUpdated(true)),
                      ),
                      SizedBox(height: Spacing.sm),
                      CurrentGestationCard(
                        current: _controller.currentPregnancyData,
                        onEdit: () =>
                            Modular.to.pushNamed(routeGravidezAtual).then((_) => _controller.setUpdated(true)),
                      ),
                      SizedBox(height: Spacing.sm),
                      ExpectationsCard(
                        expectations: _controller.expectationsData,
                        onEdit: () => Modular.to.pushNamed(routeExpectativa).then((_) => _controller.setUpdated(true)),
                      ),
                      SizedBox(height: Spacing.sm),
                      BirthMomentCard(
                        birthMoment: _controller.birthMomentData,
                        onEdit: () => Modular.to.pushNamed(routeMomentoParto).then((_) => _controller.setUpdated(true)),
                      ),
                      SizedBox(height: Spacing.sm),
                      PainReliefCard(
                        painRelief: _controller.painReliefData,
                        onEdit: () => Modular.to.pushNamed(routeAlivioDor).then((_) => _controller.setUpdated(true)),
                      ),
                      SizedBox(height: Spacing.sm),
                      BirthExpectationsCard(
                        birth: _controller.birthData,
                        onEdit: () => Modular.to.pushNamed(routeNascimento).then((_) => _controller.setUpdated(true)),
                      ),
                      SizedBox(height: Spacing.sm),
                      DesiresExpectationsCard(
                        observations: _controller.observationsData,
                        onEdit: () => Modular.to.pushNamed(routeObservacoes).then((_) => _controller.setUpdated(true)),
                      ),
                    ],
                  ),
                ),
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
