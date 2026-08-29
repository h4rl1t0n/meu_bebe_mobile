import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/vacina/vacina_model.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/vacina/vacina_repository.dart';

part 'vaccines_controller.g.dart';

class VaccinesController = VaccinesControllerBase with _$VaccinesController;

/// Controlador de VACINAS (Home), com a API como fonte de verdade.
///
/// O catálogo (7 itens fixos) vive no Flutter ([VacinaCatalogo]); o registro
/// persistido vem de [VacinaRepository]. A associação item↔registro é por
/// `nome` (identificador semântico estável), NUNCA por índice/UUID. Ao marcar
/// uma vacina ainda não cadastrada, ela é criada na primeira alteração (POST);
/// caso já exista, alterna `aplicada` via PUT no UUID real.
abstract class VaccinesControllerBase with Store {
  final PerfilRepository perfilRepository;
  final VacinaRepository vacinaRepository;

  VaccinesControllerBase(this.perfilRepository, this.vacinaRepository);

  @observable
  bool isLoading = false;

  /// `false` quando não há gestação ativa — a tela mostra aviso amigável.
  @observable
  bool hasGestacao = false;

  @observable
  var vacinas = ObservableList<VacinaModel>();

  /// UUID real da gestação ativa (resolvido da API). Nunca um id SQLite/0/1.
  String? _gestacaoId;

  /// Protege contra toggle duplo (double-tap) — uma mutação por vez.
  bool _busy = false;

  @action
  Future<void> initialize() async {
    isLoading = true;
    try {
      await _resolveGestacao();
      final gid = _gestacaoId;
      if (gid == null) {
        hasGestacao = false;
        vacinas.clear();
        return;
      }
      hasGestacao = true;
      await _getVacinas();
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
  Future<void> _getVacinas() async {
    final result = await vacinaRepository.listVacinas(_gestacaoId!);
    switch (result) {
      case Success():
        vacinas.clear();
        vacinas.addAll(result.success);
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  /// Registro API correspondente ao `nome` canônico (ou `null` se ausente).
  VacinaModel? vacinaPorNome(String nome) {
    for (final v in vacinas) {
      if (v.nome == nome) return v;
    }
    return null;
  }

  /// Alterna `aplicada` da vacina canônica `nome`.
  ///
  /// Ausente na API → cria (`aplicada: true`) na primeira alteração. Existente →
  /// PUT no UUID real. Nunca usa índice/posição para endereçar o recurso.
  @action
  Future<void> toggleVacina(String nome) async {
    if (_busy) return;
    final gid = _gestacaoId;
    if (gid == null) {
      Messages.showInfo('Cadastre sua gestação para marcar vacinas.');
      return;
    }
    _busy = true;
    try {
      final existente = vacinaPorNome(nome);
      final result = existente == null
          ? await vacinaRepository.createVacina(
              gid,
              VacinaModel(id: '', nome: nome, aplicada: true),
            )
          : await vacinaRepository.updateVacina(
              gid,
              existente.copyWith(aplicada: !existente.aplicada),
            );
      switch (result) {
        case Success():
          await _getVacinas();
        case Error(error: final failure):
          Messages.showError(failure.message);
      }
    } finally {
      _busy = false;
    }
  }
}
