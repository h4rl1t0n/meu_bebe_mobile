import 'package:flutter/material.dart';

import '../../../../../../core/ui/theme/styles/colors_app.dart';
import '../../../../../../core/ui/theme/styles/text_styles.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  bool _notificacoesAtivas = true;
  bool _lembretesConsulta = true;
  bool _lembretesVacina = true;
  bool _lembretesMedicacao = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.secondary,
      appBar: AppBar(title: const Text('Configuracoes'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Notificacoes', textStyles),
          _switchTile('Notificacoes ativas', _notificacoesAtivas, (v) => setState(() => _notificacoesAtivas = v)),
          const Divider(),
          _sectionTitle('Lembretes', textStyles),
          _switchTile('Lembretes de consulta', _lembretesConsulta, (v) => setState(() => _lembretesConsulta = v)),
          _switchTile('Lembretes de vacina', _lembretesVacina, (v) => setState(() => _lembretesVacina = v)),
          _switchTile('Lembretes de medicacao', _lembretesMedicacao, (v) => setState(() => _lembretesMedicacao = v)),
          const Divider(),
          _sectionTitle('Conta', textStyles),
          ListTile(
            title: const Text('Alterar senha'),
            leading: const Icon(Icons.lock_outline),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Excluir conta'),
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Excluir conta'),
                  content: const Text('Tem certeza que deseja excluir sua conta? Esta acao nao pode ser desfeita.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Excluir', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, TextStyles textStyles) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: textStyles.titleSmallStyle),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeThumbColor: context.colors.text,
      contentPadding: EdgeInsets.zero,
    );
  }
}
