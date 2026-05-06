import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../app_module.dart';
import '../../core/ui/theme/styles/colors_app.dart';

class InicializarAppPage extends StatefulWidget {
  const InicializarAppPage({super.key});

  @override
  State<InicializarAppPage> createState() => _InicializarAppPageState();
}

class _InicializarAppPageState extends State<InicializarAppPage> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 2000));
      Modular.to.pushReplacementNamed(routeLogin);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.primary,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.primary.withValues(alpha: 0.85)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset('assets/images/maternity.png', width: 100, height: 100, fit: BoxFit.contain),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator.adaptive(
                    backgroundColor: colors.secondary,
                    valueColor: AlwaysStoppedAnimation(colors.darkText),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Preparando tudo para você...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: colors.darkText),
                ),

                const SizedBox(height: 6),

                Text(
                  'Carregando informações do bebê',
                  style: TextStyle(fontSize: 14, color: colors.darkText.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
