import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/ui/theme/styles/colors_app.dart';
import '../../../core/ui/theme/styles/design_tokens.dart';
import '../../../core/ui/theme/styles/text_styles.dart';

/// Componentes reutilizáveis de pergunta do formulário DSS (FASE 9G-FIX2).
///
/// Padronizam a semântica dos widgets (item 27 da diretiva): cada pergunta
/// exibe *Título* → `*` de obrigatoriedade → instrução curta → opções →
/// erro inline. Nenhum campo é pré-selecionado; `false` (Não) é uma resposta
/// VÁLIDA e distinta de `null` (não respondido).

/// Título de pergunta com indicador de obrigatoriedade (`*`).
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
    style: textStyles.subTitleSmallStyle.copyWith(
      color: colors.onSurface,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// Pergunta binária (Sim/Não) com três estados: `null` (não respondido),
/// `true` (Sim) e `false` (Não).
///
/// Nada fica pré-selecionado — `false` (Não) é uma resposta VÁLIDA e distinta
/// de `null` (não respondido). Substitui o `Switch`/`SwitchListTile`, cujo
/// estado OFF era ambíguo (parecia "Não" mas internamente ficava `null`).
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
        RadioGroup<bool>(
          groupValue: value,
          onChanged: onChanged,
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(title: const Text('Sim'), value: true, contentPadding: EdgeInsets.zero),
              ),
              Expanded(
                child: RadioListTile<bool>(title: const Text('Não'), value: false, contentPadding: EdgeInsets.zero),
              ),
            ],
          ),
        ),
        if (hasError) ...[SizedBox(height: Spacing.xs), Text(errorText, style: textStyles.errorStyle)],
      ],
    );
  }
}

/// Pergunta de múltipla escolha como `FilterChip` (toca para marcar/desmarcar).
///
/// Exibe instrução "Selecione uma ou mais opções.", separador visual `ou` antes
/// da opção exclusiva (ex.: "Nenhuma das opções") e erro inline quando
/// obrigatória e vazia.
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
        // FASE 9G-FIX3 (reatividade): as leituras de `selected` (isEmpty /
        // contains) devem ocorrer DENTRO de uma reação MobX. O `Observer` da
        // aba lê apenas a REFERÊNCIA do ObservableList (átomo do campo), nunca
        // o conteúdo; as mutações add/remove/clear notificam o átomo INTERNO da
        // lista, que não foi assinado por ninguém. Este `Observer` interno lê o
        // conteúdo e redesenha os chips imediatamente a cada ação, sem depender
        // de outra pergunta.
        Observer(
          builder: (_) {
            final hasError = required && showError && selected.isEmpty;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.xs,
                  children: [for (final option in normalOptions) _chip(context, option)],
                ),
                if (exclusiveOption != null) ...[
                  SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      const Expanded(child: Divider(height: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
                        child: Text('ou', style: textStyles.caption),
                      ),
                      const Expanded(child: Divider(height: 1)),
                    ],
                  ),
                  SizedBox(height: Spacing.xs),
                  _chip(context, exclusiveOption),
                ],
                if (hasError) ...[
                  SizedBox(height: Spacing.xs),
                  Text(errorText, style: textStyles.errorStyle),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, T option) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final isSelected = selected.contains(option);
    final isExclusive = option == exclusive;

    return FilterChip(
      label: Text(labelOf(option)),
      selected: isSelected,
      // Seleção NÃO apenas por cor: check visível + fundo + borda.
      showCheckmark: true,
      checkmarkColor: Colors.white,
      backgroundColor: colors.surface,
      selectedColor: isExclusive ? colors.primary600 : colors.primary500,
      side: BorderSide(
        color: isSelected ? colors.primary500 : colors.primary300,
        width: isSelected ? 1.5 : 1,
      ),
      labelStyle: textStyles.buttonTextStyle.copyWith(
        color: isSelected ? Colors.white : colors.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        letterSpacing: 0,
      ),
      onSelected: (_) => onToggle(option),
    );
  }
}
