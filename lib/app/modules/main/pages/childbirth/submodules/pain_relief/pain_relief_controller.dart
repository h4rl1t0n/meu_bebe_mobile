import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository.dart';

part 'pain_relief_controller.g.dart';

class PainReliefController = PainReliefControllerBase with _$PainReliefController;

/// Controlador de ALÍVIO DA DOR (seção do Plano de Parto) — API como fonte.
///
/// O estado de seleção do formulário vive AQUI (observables), não em
/// `TextEditingController`/bools locais da página: a UI apenas lê e chama os
/// setters, sem `setState`.
abstract class PainReliefControllerBase with Store {
  final PlanoPartoRepository planoPartoRepository;
  final PerfilRepository perfilRepository;

  PainReliefControllerBase(this.planoPartoRepository, this.perfilRepository);

  @observable
  bool saved = false;

  @observable
  bool isLoading = false;

  @observable
  bool hasGestacao = false;

  @observable
  PlanoPartoModel? plano;

  @observable
  TriState querAlivioDor = TriState.naoSei;

  @observable
  bool massagem = false;

  @observable
  bool exerciciosBola = false;

  @observable
  bool exerciciosRespiracao = false;

  @observable
  bool banhoChuveiro = false;

  @observable
  bool banhoBanheira = false;

  @observable
  bool acupuntura = false;

  @observable
  bool acupressao = false;

  @observable
  bool outroMetodo = false;

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
        _hydrate(null);
        return;
      }
      hasGestacao = true;
      final result = await planoPartoRepository.getPlanoParto(gid);
      switch (result) {
        case Success():
          plano = result.success ?? PlanoPartoModel.empty();
          _hydrate(plano);
        case Error(error: final failure):
          Messages.showError(failure.message);
          plano = null;
          loadFailed = true;
          _hydrate(null);
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

  /// Re-hidrata o estado de seleção a partir do plano carregado.
  @action
  void _hydrate(PlanoPartoModel? plano) {
    querAlivioDor = TriState.fromValue(plano?.querAlivioDor);
    massagem = plano?.massagem ?? false;
    exerciciosBola = plano?.exerciciosBola ?? false;
    exerciciosRespiracao = plano?.exerciciosRespiracao ?? false;
    banhoChuveiro = plano?.banhoChuveiro ?? false;
    banhoBanheira = plano?.banhoBanheira ?? false;
    acupuntura = plano?.acupuntura ?? false;
    acupressao = plano?.acupressao ?? false;
    outroMetodo = plano?.outroMetodo ?? false;
  }

  @action
  void setQuerAlivioDor(TriState value) => querAlivioDor = value;

  @action
  void setMassagem(bool value) => massagem = value;

  @action
  void setExerciciosBola(bool value) => exerciciosBola = value;

  @action
  void setExerciciosRespiracao(bool value) => exerciciosRespiracao = value;

  @action
  void setBanhoChuveiro(bool value) => banhoChuveiro = value;

  @action
  void setBanhoBanheira(bool value) => banhoBanheira = value;

  @action
  void setAcupuntura(bool value) => acupuntura = value;

  @action
  void setAcupressao(bool value) => acupressao = value;

  @action
  void setOutroMetodo(bool value) => outroMetodo = value;

  @action
  Future<void> savePainRelief() async {
    if (_busy) return;
    final gid = _gestacaoId;
    if (gid == null) {
      Messages.showInfo('Cadastre sua gestação para salvar o plano de parto.');
      return;
    }
    if (loadFailed) {
      Messages.showInfo('Não foi possível carregar o plano de parto. Tente novamente antes de salvar.');
      return;
    }
    _busy = true;
    saved = false;
    try {
      final updated = (plano ?? PlanoPartoModel.empty()).copyWith(
        querAlivioDor: querAlivioDor.value,
        massagem: massagem,
        exerciciosBola: exerciciosBola,
        exerciciosRespiracao: exerciciosRespiracao,
        banhoChuveiro: banhoChuveiro,
        banhoBanheira: banhoBanheira,
        acupuntura: acupuntura,
        acupressao: acupressao,
        outroMetodo: outroMetodo,
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
