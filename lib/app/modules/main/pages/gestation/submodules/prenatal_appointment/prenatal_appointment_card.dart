import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/appointment.dart';
import '../../../../../../repositories/appointments/appointments_repository.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/item_tile_with_list.dart';

class PrenatalAppointmentCard extends StatefulWidget {
  const PrenatalAppointmentCard({super.key, required this.list});

  final List<String> list;

  @override
  State<PrenatalAppointmentCard> createState() => _PrenatalAppointmentCardState();
}

class _PrenatalAppointmentCardState extends State<PrenatalAppointmentCard> {
  late final AppointmentsRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = Modular.get<AppointmentsRepository>();
  }

  Future<void> _addAppointment() async {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar consulta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Titulo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Data', border: OutlineInputBorder()),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descricao', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result == true && titleCtrl.text.isNotEmpty) {
      await _repo.saveAppointment(
        appointment: Appointment(
          id: 0,
          title: titleCtrl.text,
          appointmentDate: dateCtrl.text.isNotEmpty ? dateCtrl.text : DateTime.now().toIso8601String(),
          description: descCtrl.text,
        ),
      );
      if (mounted) {
        Messages.showSuccess('Consulta adicionada');
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [ItemTileWithList(title: 'Consultas de pre-natal', list: widget.list)],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _addAppointment,
              child: const Text('Adicionar consulta'),
            ),
          ),
        ],
      ),
    );
  }
}
