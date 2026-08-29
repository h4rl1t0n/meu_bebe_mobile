import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../../app_module.dart';
import '../../../../../core/helpers/messages.dart';
import '../../../../../core/ui/theme/styles/design_tokens.dart';
import '../../../../../core/ui/theme/styles/text_styles.dart';
import '../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../model/plano_parto/plano_parto_model.dart';
import '../../../widgets/base_card.dart';
import '../../../widgets/custom_item_tile.dart';

/// Card "Resumo do plano de parto" embutido na [ChildbirthPage] (aba Parto).
///
/// Dumb widget: recebe o [PlanoPartoModel] por PARÂMETRO, carregado pelo
/// `ChildbirthController` do escopo ativo (MainModule). NÃO resolve controllers
/// via `Modular.get` — o `ChildbirthResumeController` pertence ao
/// `ChildbirthResumeModule` (rota irmã), que não está ativo quando a aba é
/// construída. Apenas navega (botão "Visualizar") e formata o compartilhamento.
class ChildbirthResumeCard extends StatelessWidget {
  const ChildbirthResumeCard({super.key, required this.plano});

  final PlanoPartoModel? plano;

  String _via(String? v) => v == null ? 'Não definido' : ViaParto.fromValue(v).label;

  String _tri(String? v) => v == null ? 'Não definido' : TriState.fromValue(v).label;

  String _actor(String? v) => v == null ? 'Não definido' : ActorChoice.fromValue(v).label;

  String _position(PlanoPartoModel? plano) {
    if (plano == null) return 'Não definido';
    final outra = plano.outraPosicao;
    if (outra != null && outra.isNotEmpty) return outra;
    final pos = plano.posicaoPreferida;
    if (pos == null || pos.isEmpty) return 'Não definido';
    return PosicaoParto.fromValue(pos)?.label ?? 'Não definido';
  }

  void _shareResume() {
    final buffer = StringBuffer('''
=== Plano de Parto - Meu Bebê ===

Via de parto: ${_via(plano?.viaParto)}
Posição: ${_position(plano)}
Anestesia: ${_tri(plano?.anestesia)}
Acompanhante: ${_tri(plano?.acompanhante)}
Corte do cordão: ${_actor(plano?.quemCortaCordao)}
Primeiro banho: ${_actor(plano?.primeiroBanho)}
''');

    Messages.showInfo('Compartilhar plano de parto será implementado em breve.\n\n$buffer');
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        children: [
          Text('Resumo do plano de parto', style: context.textStyles.titleSmallStyle),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Via de parto', content: _via(plano?.viaParto)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Posição', content: _position(plano)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Anestesia', content: _tri(plano?.anestesia)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: 'Acompanhante', content: _tri(plano?.acompanhante)),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomItemTile(flex: 1, title: 'Corte cordão', content: _actor(plano?.quemCortaCordao)),
              const SizedBox(width: Spacing.sm),
              CustomItemTile(flex: 1, title: '1° banho', content: _actor(plano?.primeiroBanho)),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Modular.to.pushNamed(routeVisualizarResumo);
                    },
                    child: const Text('Visualizar'),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(onPressed: _shareResume, child: const Text('Compartilhar')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
