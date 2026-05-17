import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../../core/ui/theme/styles/colors_app.dart';
import '../profile_data_controller.dart';
import '../../../../../../../core/ui/theme/styles/text_styles.dart';

class CustomTextField extends StatefulWidget {
  final ProfileDataController controller;
  final TextEditingController textController;
  final String label;
  final FormFieldValidator<String?>? validator;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.textController,
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TextFormField(
      style: context.textStyles.textStyle.copyWith(color: colors.darkText),
      controller: widget.textController,
      validator: widget.validator,
      decoration: InputDecoration(fillColor: colors.primary, label: Text(widget.label)),
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
    );
  }
}
