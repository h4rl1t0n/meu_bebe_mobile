import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../app_module.dart';
import '../../core/constants/images.dart';
import '../../core/ui/theme/styles/colors_app.dart';
import '../../core/ui/theme/styles/design_tokens.dart';
import '../../core/ui/theme/styles/text_styles.dart';

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
                      padding: EdgeInsets.all(Spacing.xxl),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.onSurface.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(Images.maternity, width: 100, height: 100, fit: BoxFit.contain),
                    ),
                  ),
                ),

                SizedBox(height: Spacing.xl),

                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator.adaptive(
                    backgroundColor: colors.secondary,
                    valueColor: AlwaysStoppedAnimation(colors.darkText),
                  ),
                ),

                SizedBox(height: Spacing.lg),

                Text(
                  'Preparando tudo para você...',
                  textAlign: TextAlign.center,
                  style: context.textStyles.subTitleStyle,
                ),

                SizedBox(height: Spacing.xs),

                Text('Carregando informações do bebê', style: context.textStyles.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
