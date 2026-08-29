import 'package:multiple_result/multiple_result.dart';

import '../../../../../../model/avaliacao_dss/avaliacao_dss_model.dart';
import '../../../../../../model/gestacao/gestacao_model.dart';
import '../../../../../../repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';

/// Carrega o histórico de avaliações DSS da gestação atual (FASE 9G).
///
/// Classe PLANE (sem MobX): o histórico é carregado uma única vez por abertura
/// da tela. A página usa [initialize] como fonte de um `FutureBuilder`, então
/// reatividade não é necessária. Mantido testável sem codegen.
class DssController {
  final PerfilRepository perfilRepository;
  final AvaliacaoDssRepository avaliacaoDssRepository;

  DssController(this.perfilRepository, this.avaliacaoDssRepository);

  bool loading = true;
  List<AvaliacaoDssModel> avaliacoes = [];
  bool noActiveGestacao = false;
  String? error;

  Future<void> initialize() async {
    loading = true;
    error = null;
    noActiveGestacao = false;
    avaliacoes = [];

    final gestacaoResult = await perfilRepository.getGestacaoAtual();
    switch (gestacaoResult) {
      case Error(error: final failure):
        error = failure.message;
      case Success(success: null):
        noActiveGestacao = true;
      case Success(success: final GestacaoModel gestacao):
        final listResult = await avaliacaoDssRepository.list(gestacao.id);
        switch (listResult) {
          case Error(error: final failure):
            error = failure.message;
          case Success(success: final list):
            avaliacoes = list;
        }
    }

    loading = false;
  }
}
