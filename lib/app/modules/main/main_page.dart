import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'main_controller.dart';
import 'pages/childbirth/childbirth_page.dart';
import 'pages/gestation/gestation_page.dart';
import 'pages/home/home_page.dart';
import 'pages/profile/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  final controller = Modular.get<MainController>();
  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Observer(builder: (_) => Text(controller.titulo))),
      body: TabBarView(
        controller: tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [HomePage(), GestationPage(), ChildbirthPage(), ProfilePage()],
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
                icon: Icon(CupertinoIcons.house),
                selectedIcon: Icon(CupertinoIcons.house_fill),
                label: 'Home',
                tooltip: 'Home',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.heart),
                selectedIcon: Icon(CupertinoIcons.heart_fill),
                label: 'Gestação',
                tooltip: 'Gestação',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.doc_text),
                selectedIcon: Icon(CupertinoIcons.doc_text_fill),
                label: 'Parto',
                tooltip: 'Parto',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.person),
                selectedIcon: Icon(CupertinoIcons.person_fill),
                label: 'Perfil',
                tooltip: 'Parto',
              ),
            ],
          );
        },
      ),
    );
  }
}
