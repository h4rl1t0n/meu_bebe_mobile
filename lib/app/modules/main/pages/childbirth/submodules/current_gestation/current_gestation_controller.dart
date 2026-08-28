import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/gestacao/gestacao_model.dart';
import '../../../../../../repositories/gestacao/gestacao_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';

part 'current_gestation_controller.g.dart';

class CurrentGestationController = CurrentGestationControllerBase
    with _$CurrentGestationController;

abstract class CurrentGestationControllerBase with Store {
  final PerfilRepository perfilRepository;
  final GestacaoRepository gestacaoRepository;

  @observable
  bool loading = true;

  @observable
  GestacaoModel? model;

  CurrentGestationControllerBase(this.perfilRepository, this.gestacaoRepository);

  @action
  Future<void> initialize() async {
    loading = true;
    final result = await perfilRepository.getGestacaoAtual();

    switch (result) {
      case Success(success: final gestacao):
        model = gestacao;
      case Error():
        model = null;
    }

    loading = false;
  }

  /// Cria (POST) ou atualiza (PUT) a gestação conforme já exista uma ativa.
  /// Retorna `true` em sucesso; `false` em erro (mensagem exibida aqui).
  @action
  Future<bool> save(GestacaoModel data) async {
    if (loading) return false;
    loading = true;

    final result = model == null
        ? await gestacaoRepository.createGestacao(data)
        : await gestacaoRepository.updateGestacao(data);

    loading = false;

    switch (result) {
      case Success(success: final gestacao):
        model = gestacao;
        Messages.showSuccess('Gravidez atual salva.');
        return true;
      case Error(error: final failure):
        Messages.showError(failure.message);
        return false;
    }
  }
}
