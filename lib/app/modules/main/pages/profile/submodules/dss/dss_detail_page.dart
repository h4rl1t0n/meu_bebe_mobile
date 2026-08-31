import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/avaliacao_dss/avaliacao_dss_model.dart';
import 'dss_date_format.dart';

/// Detalhe (somente leitura) de uma avaliação DSS já persistida.
///
/// Lê o modelo de `Modular.args.data`. Nenhuma edição: o recurso é append-only
/// (FASE 9G). As respostas são exibidas por dimensão em chave/valor bruto
/// (códigos canônicos estáveis — ver [DssSchema]).
class DssDetailPage extends StatelessWidget {
  const DssDetailPage({super.key});

  static const _dimensionNames = <String, String>{
    'educacao': 'Educação',
    'trabalho': 'Trabalho e Renda',
    'saneamento': 'Saneamento',
    'saude': 'Saúde',
    'habitacao': 'Habitação',
    'alimentacao': 'Alimentação',
  };

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

    for (final entry in respostas.entries) {
      final dimension = entry.key;
      final value = entry.value;
      final label = _dimensionNames[dimension] ?? dimension;

      widgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(color: colors.surface, borderRadius: RadiusTokens.lgAll),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textStyles.subTitleStyle),
              const SizedBox(height: Spacing.sm),
              if (value is Map) ..._fields(context, value) else Text(_formatValue(value), style: textStyles.bodyMedium),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: Spacing.sm));
    }

    return widgets;
  }

  List<Widget> _fields(BuildContext context, Map value) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final rows = <Widget>[];

    value.forEach((key, v) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('$key', style: textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant)),
              ),
              Expanded(child: Text(_formatValue(v), style: textStyles.bodyMedium)),
            ],
          ),
        ),
      );
    });

    return rows;
  }

  String _formatValue(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'Sim' : 'Não';
    if (v is List) return v.isEmpty ? '—' : v.join(', ');
    return v.toString();
  }
}
