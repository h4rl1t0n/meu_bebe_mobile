import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';
import 'kick_counter_controller.dart';
import 'kick_session_model.dart';

class KickCounterPage extends StatefulWidget {
  const KickCounterPage({super.key});

  @override
  State<KickCounterPage> createState() => _KickCounterPageState();
}

class _KickCounterPageState extends State<KickCounterPage> {
  final controller = Modular.get<KickCounterController>();

  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _showInfoSheet() {
    final colors = context.colors;
    final textStyles = context.textStyles;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.sm,
          Spacing.xl,
          Spacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colors.primary500),
                SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    'Como funciona o monitoramento?',
                    style: textStyles.titleSmallStyle,
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.md),
            Text(
              'O método Cardiff ("Conte até 10") é recomendado por obstetras e pelo Ministério da Saúde para acompanhar o bem-estar do bebê a partir da 28ª semana de gestação.',
              style: textStyles.bodySmall,
            ),
            SizedBox(height: Spacing.md),
            Text(
              'Dicas para o registro:',
              style: textStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: Spacing.xs),
            Text(
              '• Escolha um momento calmo, de preferência após uma refeição.\n'
              '• Deite-se confortavelmente virada para o lado esquerdo ou sente-se relaxada.\n'
              '• A cada chute, movimento ou rolamento sentido, toque no botão para registrar.\n'
              '• O esperado é atingir 10 movimentos em até 2 horas.',
              style: textStyles.bodySmall,
            ),
            SizedBox(height: Spacing.md),
            Container(
              padding: EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: colors.warningLight,
                borderRadius: RadiusTokens.mdAll,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: colors.warning, size: 22),
                  SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      'Atenção: Se passarem 2 horas e o bebê não tiver se mexido pelo menos 10 vezes, alimente-se, beba água gelada e repita. Caso continue quieto, consulte sua maternidade ou equipe de saúde.',
                      style: textStyles.bodySmall.copyWith(color: colors.warning),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text('Contador de Movimentos', style: textStyles.titleSmallStyle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Orientações clínicas',
            onPressed: _showInfoSheet,
          ),
        ],
      ),
      body: Observer(
        builder: (_) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Alerta clínico se demorar mais de 2 horas
                if (controller.needsClinicalAttention) ...[
                  Container(
                    padding: EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: colors.warningLight,
                      borderRadius: RadiusTokens.mdAll,
                      border: Border.all(color: colors.warning),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: colors.warning),
                        SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            'Mais de 2 horas e menos de 10 movimentos registrados. Recomendamos repousar do lado esquerdo, comer algo leve e tentar novamente. Se persistir, consulte sua equipe pré-natal.',
                            style: textStyles.bodySmall.copyWith(
                              color: colors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Spacing.md),
                ],

                // Card de conclusão quando atingir a meta
                if (controller.isCompleted) ...[
                  Container(
                    padding: EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      color: colors.successLight,
                      borderRadius: RadiusTokens.mdAll,
                      border: Border.all(color: colors.success),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: colors.success, size: 28),
                        SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Meta atingida!',
                                style: textStyles.titleSmallStyle.copyWith(
                                  color: colors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '10 movimentos registrados em ${controller.formattedTime}. Seu bebê está ativo!',
                                style: textStyles.bodySmall.copyWith(
                                  color: colors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Spacing.md),
                ],

                // Indicador circular de progresso e contagem
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        height: 170,
                        child: CircularProgressIndicator(
                          value: controller.progress,
                          strokeWidth: 12,
                          backgroundColor: colors.gray200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            controller.isCompleted
                                ? colors.success
                                : colors.primary500,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${controller.kickCount}',
                            style: textStyles.titleStyle.copyWith(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: colors.primary500,
                            ),
                          ),
                          Text(
                            'de ${controller.targetKicks} chutes',
                            style: textStyles.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Spacing.lg),

                // Cronômetro da sessão
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.gray300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                        SizedBox(width: Spacing.xs),
                        Text(
                          controller.formattedTime,
                          style: textStyles.titleSmallStyle.copyWith(
                            color: colors.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: Spacing.xs),
                        Text(
                          controller.isRunning
                              ? '(ativo)'
                              : (controller.isCompleted ? '(concluído)' : '(pausado)'),
                          style: textStyles.bodySmall.copyWith(
                            color: controller.isRunning
                                ? colors.success
                                : colors.gray500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: Spacing.xl),

                // Botão principal de registro do chute
                Center(
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: ElevatedButton(
                      onPressed: controller.isCompleted
                          ? null
                          : () => controller.registerKick(),
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: colors.primary500,
                        elevation: 4,
                        padding: EdgeInsets.zero,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                          SizedBox(height: Spacing.xs),
                          Text(
                            'Chute!',
                            style: textStyles.titleSmallStyle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: Spacing.lg),

                // Botões de ação (Iniciar/Pausar, Desfazer, Reiniciar)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: Spacing.sm,
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(
                        controller.isRunning ? Icons.pause : Icons.play_arrow,
                        size: 18,
                      ),
                      label: Text(controller.isRunning ? 'Pausar' : 'Iniciar'),
                      onPressed: controller.isCompleted
                          ? null
                          : () {
                              if (controller.isRunning) {
                                controller.pauseSession();
                              } else {
                                controller.startSession();
                              }
                            },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Desfazer'),
                      onPressed: controller.kickCount > 0
                          ? () => controller.undoKick()
                          : null,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reiniciar'),
                      onPressed: controller.secondsElapsed > 0 || controller.kickCount > 0
                          ? () => controller.resetSession()
                          : null,
                    ),
                  ],
                ),

                SizedBox(height: Spacing.xl),
                const Divider(),
                SizedBox(height: Spacing.sm),

                // Histórico de sessões
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Histórico de sessões',
                      style: textStyles.titleSmallStyle,
                    ),
                    if (controller.sessionHistory.isNotEmpty)
                      TextButton(
                        onPressed: () => controller.clearHistory(),
                        child: Text(
                          'Limpar',
                          style: textStyles.bodySmall.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: Spacing.sm),

                if (controller.sessionHistory.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.md),
                    child: Center(
                      child: Text(
                        'Nenhuma sessão salva ainda.\nRegistre a atividade do bebê para guardar o histórico.',
                        textAlign: TextAlign.center,
                        style: textStyles.bodySmall.copyWith(
                          color: colors.gray500,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.sessionHistory.length,
                    separatorBuilder: (_, __) => SizedBox(height: Spacing.xs),
                    itemBuilder: (context, index) {
                      final session = controller.sessionHistory[index];
                      return _SessionHistoryCard(session: session);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  final KickSessionModel session;

  const _SessionHistoryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    final dateStr =
        '${session.date.day.toString().padLeft(2, '0')}/${session.date.month.toString().padLeft(2, '0')} às ${session.date.hour.toString().padLeft(2, '0')}:${session.date.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: RadiusTokens.mdAll),
      color: colors.surface,
      child: Padding(
        padding: EdgeInsets.all(Spacing.md),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: session.completed
                    ? colors.successLight
                    : colors.warningLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                session.completed
                    ? Icons.check
                    : Icons.access_time,
                size: 20,
                color: session.completed
                    ? colors.success
                    : colors.warning,
              ),
            ),
            SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: textStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${session.kickCount} chutes em ${session.formattedDuration}',
                    style: textStyles.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (session.completed)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: colors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Concluído',
                  style: textStyles.bodySmall.copyWith(
                    color: colors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
