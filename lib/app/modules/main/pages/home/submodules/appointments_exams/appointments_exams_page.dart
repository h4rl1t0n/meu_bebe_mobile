import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/text_styles.dart';
import 'appointments_exams_controller.dart';
import 'widgets/appointments_page.dart';
import 'widgets/exams_page.dart';

class AppointmentsExamsPage extends StatefulWidget {
  const AppointmentsExamsPage({super.key});

  @override
  State<AppointmentsExamsPage> createState() => _AppointmentsExamsPageState();
}

class _AppointmentsExamsPageState extends State<AppointmentsExamsPage> with SingleTickerProviderStateMixin {
  final controller = Modular.get<AppointmentsExamsController>();
  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Consultas e Exames', style: context.textStyles.titleSmallStyle), centerTitle: true),
      body: TabBarView(
        controller: tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          AppointmentsPage(controller: controller),
          ExamsPage(controller: controller),
        ],
      ),
      bottomNavigationBar: Observer(
        builder: (context) {
          final index = controller.index;
          return NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (index) {
              tabController.animateTo(index, duration: const Duration(milliseconds: 350), curve: Curves.easeInOutCubic);
              controller.setIndex(index);
            },
            destinations: [
              NavigationDestination(
                icon: Icon(CupertinoIcons.calendar),
                selectedIcon: Icon(CupertinoIcons.calendar_today),
                label: 'Consultas',
                tooltip: 'Consultas',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.doc_text),
                selectedIcon: Icon(CupertinoIcons.doc_text_fill),
                label: 'Exames',
                tooltip: 'Exames',
              ),
            ],
          );
        },
      ),
    );
  }
}
