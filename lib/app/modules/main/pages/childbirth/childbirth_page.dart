import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../core/extensions/size_extension.dart';
import '../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../core/ui/theme/styles/design_tokens.dart';
import 'childbirth_controller.dart';
import 'widgets/childbirth_resume_card.dart';
import 'widgets/update_childbirth_card.dart';

class ChildbirthPage extends StatefulWidget {
  const ChildbirthPage({super.key});

  @override
  State<ChildbirthPage> createState() => _ChildbirthPageState();
}

class _ChildbirthPageState extends State<ChildbirthPage> {
  /// Escopo ativo: a aba Parto é filha direta da MainPage (TabBarView), logo o
  /// [ChildbirthController] precisa estar registrado no MainModule — o módulo
  /// que de fato está ativo neste ponto da árvore de rotas.
  final _controller = Modular.get<ChildbirthController>();

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: context.screenWidth,
      color: colors.secondary,
      padding: EdgeInsets.symmetric(horizontal: Spacing.pageH, vertical: Spacing.pageV),
      child: Observer(
        builder: (_) => ListView(
          children: [
            ChildbirthResumeCard(plano: _controller.plano),
            const SizedBox(height: Spacing.lg),
            const UpdateChildbirthCard(),
          ],
        ),
      ),
    );
  }
}
