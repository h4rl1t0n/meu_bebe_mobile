import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../app_module.dart';
import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../../model/avaliacao_dss/avaliacao_dss_model.dart';
import 'dss_controller.dart';
import 'dss_date_format.dart';

/// Histórico (somente leitura) das avaliações DSS da gestação atual.
///
/// Cada item abre o detalhe (read-only). Nenhuma edição/exclusão: o recurso é
/// append-only (FASE 9G).
class DssHistoryPage extends StatefulWidget {
  const DssHistoryPage({super.key});

  @override
  State<DssHistoryPage> createState() => _DssHistoryPageState();
}

class _DssHistoryPageState extends State<DssHistoryPage> {
  late final DssController controller;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    controller = Modular.get<DssController>();
    _initFuture = controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.secondary,
      appBar: AppBar(centerTitle: true, elevation: 0, title: Text('Avaliações DSS', style: textStyles.titleSmallStyle)),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.noActiveGestacao) {
            return _emptyState(colors, textStyles, 'Nenhuma gestação ativa cadastrada.');
          }

          if (controller.error != null) {
            return _emptyState(colors, textStyles, 'Não foi possível carregar o histórico.');
          }

          if (controller.avaliacoes.isEmpty) {
            return _emptyState(colors, textStyles, 'Nenhuma avaliação realizada.');
          }

          return ListView.separated(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: controller.avaliacoes.length,
            separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, index) => _card(context, controller.avaliacoes[index]),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, AvaliacaoDssModel avaliacao) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Material(
      color: colors.surface,
      borderRadius: RadiusTokens.lgAll,
      child: InkWell(
        borderRadius: RadiusTokens.lgAll,
        onTap: () => _openDetail(avaliacao),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              Icon(CupertinoIcons.doc_fill, color: colors.darkText),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avaliação em ${formatDssDate(avaliacao.createdAt)}', style: textStyles.bodyMedium),
                    Text(
                      'Versão ${avaliacao.schemaVersion}',
                      style: textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurface.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(ColorsApp colors, TextStyles textStyles, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: textStyles.bodyMedium.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }

  void _openDetail(AvaliacaoDssModel avaliacao) {
    Modular.to.pushNamed(routeDetalheDss, arguments: avaliacao);
  }
}
