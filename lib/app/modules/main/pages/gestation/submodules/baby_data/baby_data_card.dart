import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../../repositories/exams/exams_repository.dart';
import '../../../../../../model/exam.dart';
import '../../../../widgets/base_card.dart';
import '../../../../widgets/item_tile_with_list.dart';

class BabyDataCard extends StatefulWidget {
  const BabyDataCard({super.key, required this.list});

  final List<String> list;

  @override
  State<BabyDataCard> createState() => _BabyDataCardState();
}

class _BabyDataCardState extends State<BabyDataCard> {
  late final ExamsRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = Modular.get<ExamsRepository>();
  }

  Future<void> _addExam() async {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar exame'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Titulo do exame', border: OutlineInputBorder()),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(labelText: 'Data', border: OutlineInputBorder()),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: Spacing.md),
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
      await _repo.saveExam(
        exam: Exam(
          id: 0,
          title: titleCtrl.text,
          examDate: dateCtrl.text.isNotEmpty ? dateCtrl.text : DateTime.now().toIso8601String(),
          description: descCtrl.text,
        ),
      );
      if (mounted) {
        Messages.showSuccess('Exame adicionado');
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
            children: [ItemTileWithList(title: 'Dados sobre o nascimento', list: widget.list)],
          ),
          const SizedBox(height: Spacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _addExam,
              child: const Text('Adicionar nascimento'),
            ),
          ),
        ],
      ),
    );
  }
}
