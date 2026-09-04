import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/avaliacao_dss/avaliacao_dss_model.dart';
import 'dss_date_format.dart';
import 'dss_display_mapper.dart';

/// Detalhe (somente leitura) de uma avaliação DSS já persistida.
///
/// Lê o modelo de `Modular.args.data`. Nenhuma edição: o recurso é append-only
/// (FASE 9G). As respostas são exibidas por dimensão com texto humanizado
/// (pergunta acima da resposta), sem expor os identificadores técnicos do
/// Schema DSS — o mapeamento vive centralizado em [DssDisplayMapper].
class DssDetailPage extends StatelessWidget {
  const DssDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    final data = Modular.args.data;
    final avaliacao = data is AvaliacaoDssModel ? data : null;

    return Scaffold(
      backgroundColor: colors.secondary,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text('Detalhes da avaliação', style: textStyles.titleSmallStyle),
      ),
      body: avaliacao == null
          ? Center(
              child: Text(
                'Avaliação não encontrada.',
                style: textStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(Spacing.md),
              children: [
                _header(context, avaliacao),
                const SizedBox(height: Spacing.md),
                ..._dimensions(context, avaliacao.respostas),
              ],
            ),
    );
  }

  Widget _header(BuildContext context, AvaliacaoDssModel avaliacao) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(color: colors.surface, borderRadius: RadiusTokens.lgAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avaliação em ${formatDssDate(avaliacao.createdAt)}', style: textStyles.subTitleStyle),
          const SizedBox(height: Spacing.xs),
          Text(
            'Versão do questionário: ${avaliacao.schemaVersion}',
            style: textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  List<Widget> _dimensions(BuildContext context, Map<String, dynamic> respostas) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final widgets = <Widget>[];

    final ordered = <String>[];
    for (final dimension in DssDisplayMapper.dimensionOrder) {
      if (respostas.containsKey(dimension)) ordered.add(dimension);
    }
    for (final dimension in respostas.keys) {
      if (!ordered.contains(dimension)) ordered.add(dimension);
    }

    for (final dimension in ordered) {
      final value = respostas[dimension];
      final label = DssDisplayMapper.labelForDimension(dimension);

      widgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(color: colors.surface, borderRadius: RadiusTokens.lgAll),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textStyles.subTitleStyle),
              const SizedBox(height: Spacing.md),
              if (value is Map)
                ..._fields(context, dimension, value)
              else
                Text(_formatScalar(dimension, value), style: textStyles.bodyMedium),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: Spacing.sm));
    }

    return widgets;
  }

  List<Widget> _fields(BuildContext context, String dimension, Map value) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final rows = <Widget>[];

    final ordered = DssDisplayMapper.orderedFields(dimension, value.cast<String, dynamic>());

    for (var i = 0; i < ordered.length; i++) {
      final key = ordered[i];
      final v = value[key];
      if (i > 0) rows.add(const SizedBox(height: Spacing.sm));

      rows.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DssDisplayMapper.labelForField(key),
              style: textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.xs),
            if (v is List)
              ..._listValue(context, key, v)
            else
              Text(_formatScalar(key, v), style: textStyles.bodyMedium),
          ],
        ),
      );
    }

    return rows;
  }

  List<Widget> _listValue(BuildContext context, String field, List value) {
    final textStyles = context.textStyles;
    final labels = DssDisplayMapper.formatList(field, value);
    if (labels.isEmpty) {
      return [Text('Não informado', style: textStyles.bodyMedium)];
    }

    final items = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      if (i > 0) items.add(const SizedBox(height: Spacing.xs));
      items.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: Text('•', style: textStyles.bodyMedium),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(child: Text(labels[i], style: textStyles.bodyMedium)),
          ],
        ),
      );
    }
    return items;
  }

  String _formatScalar(String field, dynamic v) => DssDisplayMapper.formatValue(field, v);
}
