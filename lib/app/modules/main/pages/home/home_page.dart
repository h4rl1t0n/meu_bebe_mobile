import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../app_module.dart';
import '../../../../core/extensions/size_extension.dart';
import '../../../../core/ui/theme/styles/colors_app.dart';
import 'widgets/home_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _spacing = 10.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: context.screenWidth,
      color: colors.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: ListView(
        children: [
          Row(
            spacing: _spacing,
            children: [
              Flexible(
                child: HomeCard(
                  icon: Icons.assignment_add,
                  title: 'Consultas e exames',
                  onTap: () {
                    Modular.to.pushNamed(routeConsultasExames);
                  },
                ),
              ),
              Flexible(
                child: HomeCard(
                  icon: Icons.vaccines,
                  title: 'Minhas vacinas',
                  onTap: () {
                    Modular.to.pushNamed(routeVacinas);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: _spacing),
          Row(
            spacing: _spacing,
            children: [
              Flexible(
                child: HomeCard(
                  icon: Icons.medication_outlined,
                  title: 'Meus medicamentos',
                  onTap: () {
                    Modular.to.pushNamed(routeMedicacoes);
                  },
                ),
              ),
              Flexible(
                child: HomeCard(
                  icon: Icons.info_outline,
                  title: 'Informações básicas',
                  onTap: () {
                    Modular.to.pushNamed(routeInformacoes);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
