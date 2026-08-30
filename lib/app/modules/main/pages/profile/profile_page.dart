import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../app_module.dart';
import '../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../core/ui/theme/styles/text_styles.dart';
import '../../main_controller.dart';
import 'submodules/dss/dss_date_format.dart';
import 'widgets/tile_button.dart';

String _avatarInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final parts = trimmed.split(' ');
  if (parts.length == 1) return parts.first[0];
  return parts.first[0] + parts.last[0];
}

/// Converte uma data ISO (`YYYY-MM-DD`) em `DD/MM/YYYY` para exibição.
/// Retorna `—` para valores nulos, vazios ou fora do padrão esperado.
String _formatIsoDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final parts = iso.split('-');
  if (parts.length != 3) return '—';
  final year = parts[0];
  final month = parts[1];
  final day = parts[2];
  if (year.length != 4 || month.length != 2 || day.length != 2) return '—';
  return '$day/$month/$year';
}

/// Valor exibível: o texto trimado ou `—` quando vazio.
String _orDash(String? value) => (value == null || value.trim().isEmpty) ? '—' : value.trim();

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final GlobalKey<FormState> formKey;
  late final MainController controller;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    formKey = GlobalKey<FormState>();
    controller = Modular.get<MainController>();
    _initFuture = controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.secondary,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Observer(
            builder: (context) {
              final displayName = controller.name.trim().isNotEmpty ? controller.name.trim().toUpperCase() : 'SEM NOME';

              return SingleChildScrollView(
                child: Column(
                  children: [
                    /// HEADER E AVATAR SOBREPOSTO
                    Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // Fundo do Cabeçalho
                        Container(
                          height: 125,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                        ),

                        // Avatar
                        Positioned(
                          bottom: -45,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.surface,
                              border: Border.all(color: colors.surface, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.onSurface.withValues(alpha: 0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: colors.darkText,
                              child: Text(
                                _avatarInitials(controller.name),
                                style: TextStyle(fontSize: 50, color: colors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50), // Espaço para compensar o avatar
                    /// NOME DO USUÁRIO
                    Text(displayName, textAlign: TextAlign.center, style: context.textStyles.titleSmallStyle),

                    SizedBox(height: Spacing.lg),

                    _gestacaoSection(context),

                    SizedBox(height: Spacing.lg),

                    _dssSection(context),

                    SizedBox(height: Spacing.lg),

                    /// MENU DE OPÇÕES (CARD)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: Spacing.md),
                      child: Container(
                        padding: EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: RadiusTokens.xxlAll,
                          boxShadow: [ElevationTokens.raisedShadow(colors.onSurface)],
                        ),
                        child: Column(
                          spacing: 5,
                          children: [
                            TileButton(
                              icon: Icons.person_outline,
                              iconColor: colors.darkText,
                              text: 'Meus Dados',
                              onTap: _abrirDadosPerfil,
                            ),
                            Divider(height: 1, color: colors.divider),
                            TileButton(
                              icon: Icons.notifications_none_outlined,
                              iconColor: colors.darkText,
                              text: 'Notificações',
                              onTap: () => Modular.to.pushNamed(routeNotificacoes),
                            ),
                            Divider(height: 1, color: colors.divider),
                            TileButton(
                              icon: Icons.settings_outlined,
                              iconColor: colors.darkText,
                              text: 'Configurações',
                              onTap: () => Modular.to.pushNamed(routeConfiguracoes),
                            ),
                            Divider(height: 1, color: colors.divider),
                            TileButton(
                              icon: Icons.info_outline,
                              iconColor: colors.darkText,
                              text: 'Sobre o app',
                              onTap: () => Modular.to.pushNamed(routeSobreApp),
                            ),
                            Divider(height: 1, color: colors.divider),
                            TileButton(
                              icon: Icons.logout_rounded,
                              iconColor: colors.error,
                              text: 'Sair',
                              onTap: () {
                                controller.logout();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Seção "Gestação atual" — exibe apenas dados já existentes no backend
  /// (DUM, local, profissional e contato do pré-natal). Sem gestação ativa
  /// (404) ou em erro, mostra o estado vazio sem detalhe técnico.
  Widget _gestacaoSection(BuildContext context) {
    final colors = context.colors;
    final gestacao = controller.gestacaoAtual;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: RadiusTokens.xxlAll,
          boxShadow: [ElevationTokens.raisedShadow(colors.onSurface)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestação atual', style: context.textStyles.subTitleStyle),
            SizedBox(height: Spacing.md),
            if (gestacao == null)
              Text(
                'Nenhuma gestação ativa cadastrada.',
                style: context.textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              )
            else ...[
              _gestacaoRow(context, 'DUM', _formatIsoDate(gestacao.dataUltimaMenstruacao)),
              _gestacaoRow(context, 'Local do pré-natal', _orDash(gestacao.localPreNatal)),
              _gestacaoRow(context, 'Profissional', _orDash(gestacao.profissionalPreNatal)),
              _gestacaoRow(context, 'Contato do local', _orDash(gestacao.contatoLocalPreNatal)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _gestacaoRow(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: context.textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant)),
          ),
          Expanded(flex: 3, child: Text(value, style: context.textStyles.bodyMedium)),
        ],
      ),
    );
  }

  Future<void> _abrirDadosPerfil() async {
    await Modular.to.pushNamed(routeDadosPerfil);
    // Ao voltar da tela, atualiza os dados
    controller.initialize();
  }

  /// Seção DSS (FASE 9G): mostra a data da última avaliação (sem probabilidade
  /// histórica) e dá acesso ao histórico (read-only) e à reavaliação
  /// (append-only).
  Widget _dssSection(BuildContext context) {
    final colors = context.colors;
    final avaliacao = controller.ultimaAvaliacaoDss;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: RadiusTokens.xxlAll,
          boxShadow: [ElevationTokens.raisedShadow(colors.onSurface)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Text('Avaliação DSS', style: context.textStyles.subTitleStyle),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.xs),
              child: Text(
                avaliacao == null
                    ? 'Nenhuma avaliação realizada.'
                    : 'Última avaliação: ${formatDssDate(avaliacao.createdAt)}',
                style: context.textStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            SizedBox(height: Spacing.sm),
            TileButton(
              icon: Icons.history,
              iconColor: colors.darkText,
              text: 'Ver avaliações',
              onTap: _abrirHistoricoDss,
            ),
            Divider(height: 1, color: colors.divider),
            TileButton(
              icon: Icons.edit_note,
              iconColor: colors.darkText,
              text: 'Responder novamente',
              onTap: _abrirReavaliacao,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirHistoricoDss() async {
    await Modular.to.pushNamed(routeHistoricoDss);
  }

  Future<void> _abrirReavaliacao() async {
    await Modular.to.pushNamed(routeForm);
    if (mounted) {
      await controller.refreshUltimaAvaliacaoDss();
    }
  }
}
