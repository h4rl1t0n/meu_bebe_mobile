import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository.dart';

part 'birth_controller.g.dart';

class BirthController = BirthControllerBase with _$BirthController;

/// Controlador de NASCIMENTO (seção do Plano de Parto) — API como fonte.
///
/// O estado de seleção do formulário vive AQUI (observables), não em
/// `TextEditingController`/bools locais da página: a UI apenas lê e chama os
/// setters, sem `setState`.
abstract class BirthControllerBase with Store {
  final PlanoPartoRepository planoPartoRepository;
  final PerfilRepository perfilRepository;

  BirthControllerBase(this.planoPartoRepository, this.perfilRepository);

  @observable
  bool saved = false;

  @observable
  bool isLoading = false;

  @observable
  bool hasGestacao = false;

  @observable
  PlanoPartoModel? plano;

  @observable
  ActorChoice quemCortaCordao = ActorChoice.naoSei;

  @observable
  bool coletaCelulasTronco = false;

  @observable
  TriState contatoPeleAPele = TriState.naoSei;

  @observable
  TriState amamentarPrimeiraHora = TriState.naoSei;

  @observable
  bool restricoesAmamentacao = false;

  @observable
  ActorChoice primeiroBanho = ActorChoice.naoSei;

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
    quemCortaCordao = ActorChoice.fromValue(plano?.quemCortaCordao);
    coletaCelulasTronco = plano?.coletaCelulasTronco ?? false;
    contatoPeleAPele = TriState.fromValue(plano?.contatoPeleAPele);
    amamentarPrimeiraHora = TriState.fromValue(plano?.amamentarPrimeiraHora);
    restricoesAmamentacao = plano?.restricoesAmamentacao ?? false;
    primeiroBanho = ActorChoice.fromValue(plano?.primeiroBanho);
  }

  @action
  void setQuemCortaCordao(ActorChoice value) => quemCortaCordao = value;

  @action
  void setColetaCelulasTronco(bool value) => coletaCelulasTronco = value;

  @action
  void setContatoPeleAPele(TriState value) => contatoPeleAPele = value;

  @action
  void setAmamentarPrimeiraHora(TriState value) => amamentarPrimeiraHora = value;

  @action
  void setRestricoesAmamentacao(bool value) => restricoesAmamentacao = value;

  @action
  void setPrimeiroBanho(ActorChoice value) => primeiroBanho = value;

  @action
  Future<void> saveBirth() async {
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
        quemCortaCordao: quemCortaCordao.value,
        coletaCelulasTronco: coletaCelulasTronco,
        contatoPeleAPele: contatoPeleAPele.value,
        amamentarPrimeiraHora: amamentarPrimeiraHora.value,
        restricoesAmamentacao: restricoesAmamentacao,
        primeiroBanho: primeiroBanho.value,
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
