import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/ui/theme/styles/colors_app.dart';
import '../../../core/ui/theme/styles/design_tokens.dart';
import '../../../core/ui/theme/styles/text_styles.dart';

/// Componentes reutilizáveis de pergunta do formulário DSS.
///
/// Padronizam a semântica (FASE 9J-PRE-FIX1): cada pergunta exibe *Título* →
/// `*` de obrigatoriedade → instrução curta → opções → erro inline. Nenhum campo
/// é pré-selecionado; `false` (Não) é uma resposta VÁLIDA e distinta de `null`
/// (não respondido).
///
/// Visão de alto nível (item 22): cada pergunta vive num [DssQuestionCard]
/// (cartão branco, borda sutil, sombra discreta) montado pelas abas.

/// Título de pergunta com indicador de obrigatoriedade (`*`).
///
/// Hierarquia tipográfica (item 21): pergunta em semibold moderado, cor forte
/// (`onSurface`), distinta das alternativas (regular).
Widget dssQuestionTitle(BuildContext context, String title, {required bool required}) {
  final colors = context.colors;
  final textStyles = context.textStyles;
  return Text.rich(
    TextSpan(
      text: title,
      children: [
        if (required)
          TextSpan(
            text: ' *',
            style: TextStyle(color: colors.error),
          ),
      ],
    ),
    style: textStyles.subTitleSmallStyle.copyWith(color: colors.onSurface, fontWeight: FontWeight.w600),
  );
}

/// Cartão branco de pergunta (item 22): radius consistente, borda sutil,
/// sombra discreta e padding interno confortável.
class DssQuestionCard extends StatelessWidget {
  final Widget child;
  const DssQuestionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.mdAll,
        border: Border.all(color: colors.gray300.withValues(alpha: 0.6)),
        boxShadow: [ElevationTokens.subtleShadow(colors.onSurface)],
      ),
      child: child,
    );
  }
}

/// Decoração padrão de inputs (item 28): fill branco, borda/radius/foco/erro
/// consistentes. Usada pelos dropdowns e campos numéricos do DSS.
InputDecoration dssInputDecoration(BuildContext context, {String? labelText, String? hintText}) {
  final colors = context.colors;
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: colors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
    enabledBorder: OutlineInputBorder(
      borderRadius: RadiusTokens.mdAll,
      borderSide: BorderSide(color: colors.gray300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: RadiusTokens.mdAll,
      borderSide: BorderSide(color: colors.primary500, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: RadiusTokens.mdAll,
      borderSide: BorderSide(color: colors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: RadiusTokens.mdAll,
      borderSide: BorderSide(color: colors.error, width: 1.5),
    ),
    border: OutlineInputBorder(
      borderRadius: RadiusTokens.mdAll,
      borderSide: BorderSide(color: colors.gray300),
    ),
  );
}

/// Pergunta binária (Sim/Não) com três estados: `null` (não respondido),
/// `true` (Sim) e `false` (Não).
///
/// Nada fica pré-selecionado. Visual (item 24): duas opções retangulares lado
/// a lado, com indicador de rádio `○`/`◉`. Selecionada = fundo primary muito
/// suave + borda primary; não selecionada = fundo branco + borda neutra.
class DssBinaryQuestion extends StatelessWidget {
  final String title;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final bool required;
  final bool showError;
  final String? instruction;
  final String errorText;

  const DssBinaryQuestion({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.showError = false,
    this.instruction,
    this.errorText = 'Campo obrigatório',
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final hasError = required && showError && value == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dssQuestionTitle(context, title, required: required),
        if (instruction != null && instruction!.isNotEmpty) ...[
          SizedBox(height: Spacing.xs),
          Text(instruction!, style: textStyles.caption),
        ],
        SizedBox(height: Spacing.sm),
        Row(
          children: [
            Expanded(child: _binaryOption(context, label: 'Sim', optionValue: true)),
            const SizedBox(width: Spacing.md),
            Expanded(child: _binaryOption(context, label: 'Não', optionValue: false)),
          ],
        ),
        if (hasError) ...[SizedBox(height: Spacing.xs), Text(errorText, style: textStyles.errorStyle)],
      ],
    );
  }

  Widget _binaryOption(BuildContext context, {required String label, required bool optionValue}) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final selected = value == optionValue;
    final radio = selected ? Icons.radio_button_checked : Icons.radio_button_unchecked;
    final radioColor = selected ? colors.primary500 : colors.gray400;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: () => onChanged(optionValue),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: Spacing.md, horizontal: Spacing.sm),
          decoration: BoxDecoration(
            color: selected ? colors.primary50 : colors.surface,
            borderRadius: RadiusTokens.mdAll,
            border: Border.all(color: selected ? colors.primary500 : colors.gray300, width: selected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(radio, size: 20, color: radioColor),
              const SizedBox(width: Spacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: textStyles.buttonTextStyle.copyWith(color: selected ? colors.primary600 : colors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pergunta categórica de escolha única (3+ alternativas).
///
/// Visual (item 25): lista vertical com rádio à esquerda, texto completo,
/// linha selecionada com fundo primary suave, toda a linha clicável e altura
/// dinâmica. Substitui o `RadioGroup`/`RadioListTile` usado anteriormente.
class DssSingleChoiceQuestion<T> extends StatelessWidget {
  final String title;
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final bool required;
  final bool showError;
  final String? instruction;
  final String errorText;

  const DssSingleChoiceQuestion({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.required = false,
    this.showError = false,
    this.instruction,
    this.errorText = 'Campo obrigatório',
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final hasError = required && showError && value == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dssQuestionTitle(context, title, required: required),
        if (instruction != null && instruction!.isNotEmpty) ...[
          SizedBox(height: Spacing.xs),
          Text(instruction!, style: textStyles.caption),
        ],
        SizedBox(height: Spacing.sm),
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.sm),
          _singleOption(context, options[i]),
        ],
        if (hasError) ...[SizedBox(height: Spacing.xs), Text(errorText, style: textStyles.errorStyle)],
      ],
    );
  }

  Widget _singleOption(BuildContext context, T option) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final selected = value == option;
    final radio = selected ? Icons.radio_button_checked : Icons.radio_button_unchecked;
    final radioColor = selected ? colors.primary500 : colors.gray400;

    return Semantics(
      button: true,
      selected: selected,
      label: labelOf(option),
      child: GestureDetector(
        onTap: () => onChanged(option),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: Spacing.md, horizontal: Spacing.md),
          decoration: BoxDecoration(
            color: selected ? colors.primary50 : colors.surface,
            borderRadius: RadiusTokens.mdAll,
            border: Border.all(color: selected ? colors.primary500 : colors.gray300, width: selected ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(radio, size: 20, color: radioColor),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  labelOf(option),
                  style: textStyles.textStyle.copyWith(color: selected ? colors.primary600 : colors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pergunta de múltipla escolha como cartões retangulares de seleção.
///
/// Visual (item 26): cartões retangulares (não "tags" redondas), `Wrap`
/// responsivo, largura determinada pelo conteúdo, sem truncamento. Selecionado
/// = fundo primary suave + borda primary + check. Exibe separador `ou` antes da
/// opção exclusiva e erro inline quando obrigatória e vazia.
class DssMultiChoiceQuestion<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final List<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onToggle;
  final bool required;
  final bool showError;
  final T? exclusive;
  final String? instruction;
  final String errorText;

  const DssMultiChoiceQuestion({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
    this.required = false,
    this.showError = false,
    this.exclusive,
    this.instruction = 'Selecione uma ou mais opções.',
    this.errorText = 'Campo obrigatório',
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;

    final normalOptions = options.where((o) => o != exclusive).toList();
    final exclusiveOption = exclusive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dssQuestionTitle(context, title, required: required),
        if (instruction != null && instruction!.isNotEmpty) ...[
          SizedBox(height: Spacing.xs),
          Text(instruction!, style: textStyles.caption),
        ],
        SizedBox(height: Spacing.sm),
        // FASE 9G-FIX3 (reatividade): as leituras de `selected` devem ocorrer
        // DENTRO de uma reação MobX — o conteúdo do ObservableList notifica o
        // átomo INTERNO da lista, assinado aqui, não pela aba.
        Observer(
          builder: (_) {
            final hasError = required && showError && selected.isEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final option in normalOptions)
                      DssMultiOption<T>(
                        option: option,
                        label: labelOf(option),
                        selected: selected.contains(option),
                        exclusive: false,
                        onTap: () => onToggle(option),
                      ),
                  ],
                ),
                if (exclusiveOption != null) ...[
                  SizedBox(height: Spacing.md),
                  _exclusiveDivider(context),
                  SizedBox(height: Spacing.sm),
                  DssMultiOption<T>(
                    option: exclusiveOption,
                    label: labelOf(exclusiveOption),
                    selected: selected.contains(exclusiveOption),
                    exclusive: true,
                    onTap: () => onToggle(exclusiveOption),
                  ),
                ],
                if (hasError) ...[SizedBox(height: Spacing.xs), Text(errorText, style: textStyles.errorStyle)],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _exclusiveDivider(BuildContext context) {
    final textStyles = context.textStyles;
    return Row(
      children: [
        const Expanded(child: Divider(height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
          child: Text('ou', style: textStyles.caption),
        ),
        const Expanded(child: Divider(height: 1)),
      ],
    );
  }
}

/// Cartão retangular de seleção de múltipla escolha (item 26).
///
/// Exposto como widget público para os testes verificarem o estado `selected`
/// de forma declarativa (análogo ao `FilterChip` anterior).
class DssMultiOption<T> extends StatelessWidget {
  final T option;
  final String label;
  final bool selected;
  final bool exclusive;
  final VoidCallback onTap;

  const DssMultiOption({
    super.key,
    required this.option,
    required this.label,
    required this.selected,
    required this.exclusive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.md),
          decoration: BoxDecoration(
            color: selected ? colors.primary50 : colors.surface,
            borderRadius: RadiusTokens.mdAll,
            border: Border.all(
              color: selected ? colors.primary500 : (exclusive ? colors.primary200 : colors.gray300),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 16, color: colors.primary500),
                const SizedBox(width: Spacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  style: textStyles.buttonTextStyle.copyWith(
                    color: selected ? colors.primary600 : colors.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pergunta de dropdown padronizada (item 9/28).
///
/// Título acima (com `*`), caixa de largura total com `Selecione uma opção`,
/// borda/radius/padding/chevron/foco/erro consistentes via [dssInputDecoration].
class DssDropdownQuestion<T> extends StatelessWidget {
  final String title;
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final bool required;
  final String? Function(T?)? validator;
  final String? hint;

  const DssDropdownQuestion({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.required = false,
    this.validator,
    this.hint = 'Selecione uma opção',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dssQuestionTitle(context, title, required: required),
        const SizedBox(height: Spacing.sm),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          hint: Text(hint ?? 'Selecione uma opção'),
          decoration: dssInputDecoration(context),
          items: [for (final option in options) DropdownMenuItem<T>(value: option, child: Text(labelOf(option)))],
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
