import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../app_module.dart';
import '../../../../core/ui/theme/styles/colors_app.dart';
import '../../main_controller.dart';
import 'widgets/tile_button.dart';

String _avatarInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final parts = trimmed.split(' ');
  if (parts.length == 1) return parts.first[0];
  return parts.first[0] + parts.last[0];
}

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
                            color: colors.primary,
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
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
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
                                style: TextStyle(
                                  fontSize: 50,
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 50), // Espaço para compensar o avatar
                    /// NOME DO USUÁRIO
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, color: context.colors.darkText, fontWeight: FontWeight.w900),
                    ),

                    const SizedBox(height: 32),

                    /// MENU DE OPÇÕES (CARD)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04), // Sombra bem mais suave
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 10),
                            ),
                          ],
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
                            Divider(height: 1, color: Colors.grey.shade100),
                            TileButton(
                              icon: Icons.notifications_none_outlined,
                              iconColor: colors.darkText,
                              text: 'Notificações',
                              onTap: () => Modular.to.pushNamed(routeNotificacoes),
                            ),
                            Divider(height: 1, color: Colors.grey.shade100),
                            TileButton(
                              icon: Icons.settings_outlined,
                              iconColor: colors.darkText,
                              text: 'Configurações',
                              onTap: () => Modular.to.pushNamed(routeConfiguracoes),
                            ),
                            Divider(height: 1, color: Colors.grey.shade100),
                            TileButton(
                              icon: Icons.info_outline,
                              iconColor: colors.darkText,
                              text: 'Sobre o app',
                              onTap: () => Modular.to.pushNamed(routeSobreApp),
                            ),
                            Divider(height: 1, color: Colors.grey.shade100),
                            TileButton(
                              icon: Icons.logout_rounded,
                              iconColor: Colors.red,
                              text: 'Sair',
                              onTap: () {
                                Modular.to.navigate(routeLogin);
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

  Future<void> _abrirDadosPerfil() async {
    await Modular.to.pushNamed(routeDadosPerfil);
    // Ao voltar da tela, atualiza os dados
    controller.initialize();
  }
}
