import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../app_module.dart';
import '../../../../../core/helpers/messages.dart';
import '../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../model/birth.dart';
import '../../../../../model/birth_moment.dart';
import '../../../widgets/base_card.dart';
import '../../../widgets/custom_item_tile.dart';
import '../submodules/childbirth_resume/childbirth_resume_controller.dart';
import '../../../../../core/ui/theme/styles/design_tokens.dart';

class ChildbirthResumeCard extends StatefulWidget {
  const ChildbirthResumeCard({super.key});

  @override
  State<ChildbirthResumeCard> createState() => _ChildbirthResumeCardState();
}

class _ChildbirthResumeCardState extends State<ChildbirthResumeCard> {
  final _resumeController = Modular.get<ChildbirthResumeController>();

  @override
  void initState() {
    super.initState();
    _resumeController.initialize();
  }

  String _birthWayLabel(BirthMoment? data) {
    if (data == null) return 'Não definido';
    return switch (data.birthWay) {
      BirthWay.vaginal => 'Vaginal',
      BirthWay.cesarean => 'Cesárea',
      BirthWay.dontKnow => 'Não sei',
    };
  }

  String _positionLabel(BirthMoment? data) {
    if (data == null || data.preferredPosition == null) return 'Não definido';
    return switch (data.preferredPosition!) {
      Positions.lyingDown => 'Deitada',
      Positions.sitting => 'Sentada',
      Positions.crouched => 'Agachada',
      Positions.aside => 'De lado',
      Positions.onKnees => 'De joelhos',
      Positions.standing => 'Em pé',
      Positions.dontKnow => 'Não sei',
      Positions.otherPosition => data.otherPosition ?? 'Outra',
    };
  }

  String _anesthesiaLabel(BirthMoment? data) {
    if (data == null) return 'Não definido';
    return switch (data.anesthesia) {
      Anesthesia.yes => 'Sim',
      Anesthesia.no => 'Não',
      Anesthesia.dontKnow => 'Não sei',
    };
  }

  String _companionLabel(BirthMoment? birthMoment) {
    return 'Não definido';
  }

  String _cordLabel(Birth? data) {
    if (data == null) return 'Não definido';
    return switch (data.whoCut) {
      WhoCutUmbilicalCord.professional => 'Profissional',
      WhoCutUmbilicalCord.companion => 'Acompanhante',
      WhoCutUmbilicalCord.me => 'Eu',
      WhoCutUmbilicalCord.dontKnow => 'Não sei',
    };
  }

  String _bathLabel(Birth? data) {
    if (data == null) return 'Não definido';
    return switch (data.firstBath) {
      FirstBath.professional => 'Profissional',
      FirstBath.companion => 'Acompanhante',
      FirstBath.me => 'Eu',
      FirstBath.dontKnow => 'Não sei',
    };
  }

  void _shareResume() {
    final data = _resumeController;

    final buffer = StringBuffer('''
=== Plano de Parto - Meu Bebê ===

Via de parto: ${_birthWayLabel(data.birthMomentData)}
Posição: ${_positionLabel(data.birthMomentData)}
Anestesia: ${_anesthesiaLabel(data.birthMomentData)}
Corte do cordão: ${_cordLabel(data.birthData)}
Primeiro banho: ${_bathLabel(data.birthData)}
''');

    Messages.showInfo('Compartilhar plano de parto será implementado em breve.\n\n$buffer');
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final brMoment = _resumeController.birthMomentData;
        final brData = _resumeController.birthData;

        return BaseCard(
          child: Column(
            children: [
              Text('Resumo do plano de parto', style: context.textStyles.titleSmallStyle),
              const SizedBox(height: Spacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomItemTile(flex: 1, title: 'Via de parto', content: _birthWayLabel(brMoment)),
                  const SizedBox(width: Spacing.sm),
                  CustomItemTile(flex: 1, title: 'Posição', content: _positionLabel(brMoment)),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomItemTile(flex: 1, title: 'Anestesia', content: _anesthesiaLabel(brMoment)),
                  const SizedBox(width: Spacing.sm),
                  CustomItemTile(flex: 1, title: 'Acompanhante', content: _companionLabel(brMoment)),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomItemTile(flex: 1, title: 'Corte cordão', content: _cordLabel(brData)),
                  const SizedBox(width: Spacing.sm),
                  CustomItemTile(flex: 1, title: '1° banho', content: _bathLabel(brData)),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Modular.to.pushNamed(routeVisualizarResumo);
                        },
                        child: const Text('Visualizar'),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _shareResume,
                        child: const Text('Compartilhar'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
