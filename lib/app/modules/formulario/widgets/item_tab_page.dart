import 'package:flutter/material.dart';

import '../../../core/ui/theme/styles/design_tokens.dart';

/// Contêiner rolável das perguntas de uma dimensão do DSS.
///
/// Cada pergunta chega já embrulhada num `DssQuestionCard` (montado pelas
/// abas); aqui apenas garantimos padding horizontal/lateral consistente e um
/// respiro inferior para a última pergunta não encostar no botão de ação.
class ItemTabPage extends StatelessWidget {
  final List<Widget> children;
  const ItemTabPage({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.pageH,
        vertical: Spacing.pageV,
      ),
      children: children,
    );
  }
}
