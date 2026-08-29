import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/gestacao/gestacao_model.dart';
import '../../../../../../model/gestante/gestante_model.dart';
import '../../../../../../repositories/gestacao/gestacao_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';

part 'identification_controller.g.dart';

class IdentificationController = IdentificationControllerBase with _$IdentificationController;

/// Controlador de IDENTIFICAÇÃO (gestante + pré-natal), com a API como fonte de
/// verdade. O salvamento escreve a GESTANTE ([PerfilRepository]) e depois a
/// GESTAÇÃO ([GestacaoRepository]) — nunca no SQLite.
abstract class IdentificationControllerBase with Store {
  final PerfilRepository perfilRepository;
  final GestacaoRepository gestacaoRepository;

  IdentificationControllerBase(this.perfilRepository, this.gestacaoRepository);

  @observable
  bool _saved = false;

  @computed
  bool get saved => _saved;

  @action
  void setSaved(bool value) => _saved = value;

  @observable
  GestanteModel? gestante;

  @observable
  GestacaoModel? gestacao;

  @observable
  bool isLoading = false;

  bool _busy = false;

  @action
  Future<void> initialize() async {
    isLoading = true;
    try {
      await _resolveGestante();
      await _resolveGestacao();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> _resolveGestante() async {
    final result = await perfilRepository.getGestante();
    switch (result) {
      case Error():
        gestante = null;
      case Success():
        gestante = result.success;
    }
  }

  @action
  Future<void> _resolveGestacao() async {
    final result = await perfilRepository.getGestacaoAtual();
    switch (result) {
      case Error():
        gestacao = null;
      case Success():
        gestacao = result.success;
    }
  }

  /// Cria/atualiza a gestante e depois a gestação (pré-natal, preservando a
  /// DUM já existente). Ambos os writes usam o contrato estável do backend.
  @action
  Future<void> saveIdentification({
    required String nome,
    String? nomeSocial,
    String? dataNascimento,
    String? cpf,
    String? cns,
    String? localPreNatal,
    String? profissionalPreNatal,
    String? contatoLocalPreNatal,
  }) async {
    if (_busy) return;
    _busy = true;
    try {
      final gestanteModel = GestanteModel(
        id: gestante?.id ?? '',
        nome: nome,
        nomeSocial: nomeSocial,
        dataNascimento: dataNascimento,
        cpf: cpf,
        cns: cns,
      );
      final gestanteResult = gestante == null
          ? await perfilRepository.createGestante(gestanteModel)
          : await perfilRepository.updateGestante(gestanteModel);
      switch (gestanteResult) {
        case Error(error: final failure):
          Messages.showError(failure.message);
          return;
        case Success(success: final saved):
          gestante = saved;
      }

      final gestacaoModel = GestacaoModel(
        id: gestacao?.id ?? '',
        dataUltimaMenstruacao: gestacao?.dataUltimaMenstruacao,
        localPreNatal: localPreNatal,
        profissionalPreNatal: profissionalPreNatal,
        contatoLocalPreNatal: contatoLocalPreNatal,
      );
      final gestacaoResult = gestacao == null
          ? await gestacaoRepository.createGestacao(gestacaoModel)
          : await gestacaoRepository.updateGestacao(gestacaoModel);
      switch (gestacaoResult) {
        case Error(error: final failure):
          Messages.showError(failure.message);
          return;
        case Success(success: final saved):
          gestacao = saved;
      }

      _saved = true;
      Messages.showSuccess('Dados salvos com sucesso');
    } finally {
      _busy = false;
    }
  }
}
