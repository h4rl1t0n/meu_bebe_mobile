import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      icon: Icons.calendar_today,
      title: 'Consulta de pre-natal amanha',
      subtitle: 'Lembrete: consulta marcada para 09:00',
      time: 'Ontem',
    ),
    _NotificationItem(
      icon: Icons.vaccines,
      title: 'Vacina dTpa disponivel',
      subtitle: 'Voce esta no periodo recomendado para a vacina dTpa',
      time: '2 dias atras',
    ),
    _NotificationItem(
      icon: Icons.event_note,
      title: 'Exame de ultrassom agendado',
      subtitle: 'Seu exame foi agendado para 15/06/2026',
      time: '3 dias atras',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.secondary,
      appBar: AppBar(title: const Text('Notificacoes'), centerTitle: true),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 80, color: colors.darkText.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('Nenhuma notificacao', style: textStyles.titleSmallStyle),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (_, index) {
                final notif = _notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors.primary,
                    child: Icon(notif.icon, color: colors.darkText),
                  ),
                  title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(notif.subtitle),
                  trailing: Text(notif.time, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                );
              },
            ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationItem({required this.icon, required this.title, required this.subtitle, required this.time});
}
