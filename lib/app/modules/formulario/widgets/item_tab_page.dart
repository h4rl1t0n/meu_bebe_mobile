import 'package:flutter/material.dart';

import '../../../core/ui/theme/styles/colors_app.dart';
import '../../../core/ui/theme/styles/text_styles.dart';

class ItemTabPage extends StatefulWidget {
  final String title;
  final List<Widget> children;
  const ItemTabPage({super.key, required this.title, required this.children});

  @override
  State<ItemTabPage> createState() => _ItemTabPageState();
}

class _ItemTabPageState extends State<ItemTabPage> {
  String get title => widget.title;
  List<Widget> get children => widget.children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 15),
          child: Text(title, style: textStyles.titleStyle.copyWith(fontSize: 28, color: colors.darkText)),
        ),
        Expanded(child: ListView(shrinkWrap: true, children: children)),
      ],
    );
  }
}
