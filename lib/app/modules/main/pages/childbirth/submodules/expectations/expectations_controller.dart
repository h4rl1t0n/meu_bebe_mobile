import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository.dart';

part 'expectations_controller.g.dart';

class ExpectationsController = ExpectationsControllerBase with _$ExpectationsController;

/// Controlador de EXPECTATIVAS (seção do Plano de Parto), com a API como fonte
/// de verdade. Cada salvamento faz GET (em memória) → merge da seção → PUT do
/// plano COMPLETO (28 campos), preservando as demais seções.
///
/// O estado de seleção do formulário vive AQUI (observables), não em
/// `TextEditingController` locais da página: a UI apenas lê e chama os setters,
/// sem `setState`.
abstract class ExpectationsControllerBase with Store {
  final PlanoPartoRepository planoPartoRepository;
  final PerfilRepository perfilRepository;

  ExpectationsControllerBase(this.planoPartoRepository, this.perfilRepository);

  @observable
  bool saved = false;

  @observable
  bool isLoading = false;

  @observable
  bool hasGestacao = false;

  @observable
  PlanoPartoModel? plano;

  @observable
  TriState acompanhante = TriState.naoSei;

  @observable
  TriState rasparPelosIntimos = TriState.naoSei;

  @observable
  TriState lavagemIntestinal = TriState.naoSei;

  @observable
  TriState ambientePoucaLuz = TriState.naoSei;

  @observable
  TriState ouvirMusica = TriState.naoSei;

  @observable
  TriState beberLiquidos = TriState.naoSei;

  @observable
  TriState registrarFotosVideos = TriState.naoSei;

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
    acompanhante = TriState.fromValue(plano?.acompanhante);
    rasparPelosIntimos = TriState.fromValue(plano?.rasparPelosIntimos);
    lavagemIntestinal = TriState.fromValue(plano?.lavagemIntestinal);
    ambientePoucaLuz = TriState.fromValue(plano?.ambientePoucaLuz);
    ouvirMusica = TriState.fromValue(plano?.ouvirMusica);
    beberLiquidos = TriState.fromValue(plano?.beberLiquidos);
    registrarFotosVideos = TriState.fromValue(plano?.registrarFotosVideos);
  }

  @action
  void setAcompanhante(TriState value) => acompanhante = value;

  @action
  void setRasparPelosIntimos(TriState value) => rasparPelosIntimos = value;

  @action
  void setLavagemIntestinal(TriState value) => lavagemIntestinal = value;

  @action
  void setAmbientePoucaLuz(TriState value) => ambientePoucaLuz = value;

  @action
  void setOuvirMusica(TriState value) => ouvirMusica = value;

  @action
  void setBeberLiquidos(TriState value) => beberLiquidos = value;

  @action
  void setRegistrarFotosVideos(TriState value) => registrarFotosVideos = value;

  @action
  Future<void> saveExpectations() async {
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
        acompanhante: acompanhante.value,
        rasparPelosIntimos: rasparPelosIntimos.value,
        lavagemIntestinal: lavagemIntestinal.value,
        ambientePoucaLuz: ambientePoucaLuz.value,
        ouvirMusica: ouvirMusica.value,
        beberLiquidos: beberLiquidos.value,
        registrarFotosVideos: registrarFotosVideos.value,
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
