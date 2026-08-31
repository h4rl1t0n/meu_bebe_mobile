import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../model/consulta/consulta_model.dart';
import '../../../../../../repositories/consulta/consulta_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../widgets/add_consulta_dialog.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/item_tile_with_list.dart';

class PrenatalAppointmentCard extends StatefulWidget {
  const PrenatalAppointmentCard({super.key, required this.list, this.onChanged});

  final List<String> list;
  final VoidCallback? onChanged;

  @override
  State<PrenatalAppointmentCard> createState() => _PrenatalAppointmentCardState();
}

class _PrenatalAppointmentCardState extends State<PrenatalAppointmentCard> {
  late final ConsultaRepository _repo;
  late final PerfilRepository _perfil;

  @override
  void initState() {
    super.initState();
    _repo = Modular.get<ConsultaRepository>();
    _perfil = Modular.get<PerfilRepository>();
  }

  Future<void> _addAppointment() async {
    final ConsultaModel? consulta = await showAddConsultaDialog(context);
    if (consulta == null || !mounted) return;

    final gestacaoId = await _gestacaoId();
    if (!mounted) return;
    if (gestacaoId == null) {
      Messages.showInfo('Cadastre sua gestação para adicionar consultas.');
      return;
    }

    final saveResult = await _repo.createConsulta(gestacaoId, consulta);
    if (!mounted) return;
    switch (saveResult) {
      case Success():
        Messages.showSuccess('Consulta adicionada');
        widget.onChanged?.call();
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  Future<String?> _gestacaoId() async {
    final result = await _perfil.getGestacaoAtual();
    return switch (result) {
      Success() => result.success?.id,
      Error() => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: ItemTileWithList(title: 'Consultas de pré-natal', list: widget.list),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(onPressed: _addAppointment, child: const Text('Adicionar consulta')),
          ),
        ],
      ),
    );
  }
}
