import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../model/exame/exame_model.dart';
import '../../../../../../repositories/exame/exame_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../widgets/add_exame_dialog.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/item_tile_with_list.dart';

class BabyDataCard extends StatefulWidget {
  const BabyDataCard({super.key, required this.list, this.onChanged});

  final List<String> list;
  final VoidCallback? onChanged;

  @override
  State<BabyDataCard> createState() => _BabyDataCardState();
}

class _BabyDataCardState extends State<BabyDataCard> {
  late final ExameRepository _repo;
  late final PerfilRepository _perfil;

  @override
  void initState() {
    super.initState();
    _repo = Modular.get<ExameRepository>();
    _perfil = Modular.get<PerfilRepository>();
  }

  Future<void> _addExam() async {
    final ExameModel? exame = await showAddExameDialog(context);
    if (exame == null || !mounted) return;

    final gestacaoId = await _gestacaoId();
    if (!mounted) return;
    if (gestacaoId == null) {
      Messages.showInfo('Cadastre sua gestação para adicionar exames.');
      return;
    }

    final saveResult = await _repo.createExame(gestacaoId, exame);
    if (!mounted) return;
    switch (saveResult) {
      case Success():
        Messages.showSuccess('Exame adicionado');
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
                child: ItemTileWithList(title: 'Exames de pré-natal', list: widget.list),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(onPressed: _addExam, child: const Text('Adicionar exame')),
          ),
        ],
      ),
    );
  }
}
