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
    _controller.initialize();
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
    return Observer(
      builder: (_) {
        if (_controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
          child: SingleChildScrollView(
            child: Column(
              children: [
                IdentificationCard(
                  name: _controller.gestante?.nome,
                  socialName: _controller.gestante?.nomeSocial,
                  birthDate: _controller.gestante?.dataNascimento,
                  nationalHealthCard: _controller.gestante?.cns,
                  localPreNatal: _controller.gestacao?.localPreNatal,
                  profissionalPreNatal: _controller.gestacao?.profissionalPreNatal,
                  contatoLocalPreNatal: _controller.gestacao?.contatoLocalPreNatal,
                  onEdit: () => Modular.to.pushNamed(routeDadosPerfil).then((_) => _controller.initialize()),
                ),
                SizedBox(height: Spacing.sm),
                HistoryCard(
                  pregnancyNumber: _controller.historico?.pregnancyNumber,
                  givenBirthNumber: _controller.historico?.givenBirthNumber,
                  abortionsNumber: _controller.historico?.abortionsNumber,
                  onEdit: () => Modular.to.pushNamed(routeHistoria).then((_) => _controller.initialize()),
                ),
                SizedBox(height: Spacing.sm),
                CurrentGestationCard(
                  lastMenstrualPeriod: _controller.gestacao?.dataUltimaMenstruacao,
                  firstUltrasound: _controller.firstUltrasound,
                  onEdit: () => Modular.to.pushNamed(routeGravidezAtual).then((_) => _controller.initialize()),
                ),
                SizedBox(height: Spacing.sm),
                ExpectationsCard(
                  plano: _controller.plano,
                  onEdit: () => Modular.to.pushNamed(routeExpectativa).then((_) => _controller.initialize()),
                ),
                SizedBox(height: Spacing.sm),
                BirthMomentCard(
                  plano: _controller.plano,
                  onEdit: () => Modular.to.pushNamed(routeMomentoParto).then((_) => _controller.initialize()),
                ),
                SizedBox(height: Spacing.sm),
                PainReliefCard(
                  plano: _controller.plano,
                  onEdit: () => Modular.to.pushNamed(routeAlivioDor).then((_) => _controller.initialize()),
                ),
                SizedBox(height: Spacing.sm),
                BirthExpectationsCard(
                  plano: _controller.plano,
                  onEdit: () => Modular.to.pushNamed(routeNascimento).then((_) => _controller.initialize()),
                ),
                SizedBox(height: Spacing.sm),
                DesiresExpectationsCard(
                  plano: _controller.plano,
                  onEdit: () => Modular.to.pushNamed(routeObservacoes).then((_) => _controller.initialize()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
