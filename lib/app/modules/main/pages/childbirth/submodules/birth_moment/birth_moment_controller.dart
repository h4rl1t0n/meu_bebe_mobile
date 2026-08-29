import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository.dart';

part 'birth_moment_controller.g.dart';

class BirthMomentController = BirthMomentControllerBase with _$BirthMomentController;

/// Controlador de MOMENTO DO PARTO (seção do Plano de Parto) — API como fonte.
abstract class BirthMomentControllerBase with Store {
  final PlanoPartoRepository planoPartoRepository;
  final PerfilRepository perfilRepository;

  BirthMomentControllerBase(this.planoPartoRepository, this.perfilRepository);

  @observable
  bool saved = false;

  @observable
  bool isLoading = false;

  @observable
  bool hasGestacao = false;

  @observable
  PlanoPartoModel? plano;

  String? _gestacaoId;
  bool _busy = false;

  /// `true` quando o GET falhou (não-404): o estado do plano é desconhecido e o
  /// `save` fica bloqueado até um novo `initialize()` bem-sucedido.
  bool loadFailed = false;

  @action
  Future<void> initialize() async {
    isLoading = true;
    loadFailed = false;
    try {
      await _resolveGestacao();
      final gid = _gestacaoId;
      if (gid == null) {
        hasGestacao = false;
        plano = null;
        return;
      }
      hasGestacao = true;
      final result = await planoPartoRepository.getPlanoParto(gid);
      switch (result) {
        case Success():
          plano = result.success ?? PlanoPartoModel.empty();
        case Error(error: final failure):
          Messages.showError(failure.message);
          plano = null;
          loadFailed = true;
      }
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> _resolveGestacao() async {
    final result = await perfilRepository.getGestacaoAtual();
    switch (result) {
      case Success():
        _gestacaoId = result.success?.id;
      case Error():
        _gestacaoId = null;
    }
  }

  @action
  Future<void> saveBirthMoment({
    required ViaParto viaParto,
    required TriState anestesia,
    required TriState corteVaginal,
    PosicaoParto? posicaoPreferida,
    String? outraPosicao,
  }) async {
    if (_busy) return;
    final gid = _gestacaoId;
    if (gid == null) {
      Messages.showInfo('Cadastre sua gestação para salvar o plano de parto.');
      return;
    }
    if (loadFailed) {
      Messages.showInfo(
        'Não foi possível carregar o plano de parto. Tente novamente antes de salvar.',
      );
      return;
    }
    _busy = true;
    saved = false;
    try {
      final updated = (plano ?? PlanoPartoModel.empty()).copyWith(
        viaParto: viaParto.value,
        anestesia: anestesia.value,
        corteVaginal: corteVaginal.value,
        posicaoPreferida: posicaoPreferida?.value,
        outraPosicao: outraPosicao,
      );
      final result = await planoPartoRepository.upsertPlanoParto(gid, updated);
      switch (result) {
        case Success(success: final savedPlano):
          plano = savedPlano;
          saved = true;
          Messages.showSuccess('Dados salvos com sucesso');
        case Error(error: final failure):
          Messages.showError(failure.message);
      }
    } finally {
      _busy = false;
    }
  }
}
