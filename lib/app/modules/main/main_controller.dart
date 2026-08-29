import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../app_module.dart';
import '../../core/auth/token_storage.dart';
import '../../model/avaliacao_dss/avaliacao_dss_model.dart';
import '../../model/gestacao/gestacao_model.dart';
import '../../repositories/auth/auth_repository.dart';
import '../../repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import '../../repositories/perfil/perfil_repository.dart';

part 'main_controller.g.dart';

class MainController = MainControllerBase with _$MainController;

abstract class MainControllerBase with Store {
  final PerfilRepository perfilRepository;
  final AuthRepository authRepository;
  final TokenStorage tokenStorage;
  final AvaliacaoDssRepository avaliacaoDssRepository;
  final void Function(String route) _navigateReplacement;

  @observable
  int index = 0;

  @observable
  String name = '';

  @observable
  String titulo = 'Home';

  @observable
  GestacaoModel? gestacaoAtual;

  @observable
  AvaliacaoDssModel? ultimaAvaliacaoDss;

  @action
  void setIndex(int value) {
    index = value;
    titulo = switch (index) {
      0 => 'Home',
      1 => 'Gestação',
      2 => 'Parto',
      3 => 'Perfil',
      _ => '-',
    };
  }

  MainControllerBase(
    this.perfilRepository,
    this.authRepository,
    this.tokenStorage,
    this.avaliacaoDssRepository, {
    void Function(String route)? navigateReplacement,
  }) : _navigateReplacement = navigateReplacement ?? _defaultNavigateReplacement;

  static void _defaultNavigateReplacement(String route) {
    Modular.to.pushReplacementNamed(route);
  }

  @action
  Future<void> initialize() async {
    // Nome real da gestante (fonte de verdade: backend). Se o perfil de
    // gestante ainda não existir, cai para o e-mail do usuário autenticado.
    var hasName = false;
    final gestanteResult = await perfilRepository.getGestante();
    switch (gestanteResult) {
      case Success(success: final gestante):
        if (gestante != null && gestante.nome.trim().isNotEmpty) {
          name = gestante.nome;
          hasName = true;
        }
      case Error():
        break;
    }

    if (!hasName) {
      final userResult = await perfilRepository.getUser();
      switch (userResult) {
        case Success(success: final user):
          name = user?.email ?? '';
        case Error():
          name = '';
      }
    }

    await refreshGestacaoAtual();
  }

  /// Recarrega somente a gestação atual (exibida no Perfil). Chamado também ao
  /// entrar na aba Perfil para refletir uma gestação recém-criada/editada sem
  /// reiniciar o app.
  @action
  Future<void> refreshGestacaoAtual() async {
    // `null` quando não há gestação ativa (404) ou em erro de conexão/sessão —
    // a UI mostra "sem gestação ativa".
    final gestacaoResult = await perfilRepository.getGestacaoAtual();
    switch (gestacaoResult) {
      case Success(success: final gestacao):
        gestacaoAtual = gestacao;
      case Error():
        gestacaoAtual = null;
    }

    await refreshUltimaAvaliacaoDss();
  }

  /// Recarrega a avaliação DSS mais recente (exibida no Perfil). Sem gestação
  /// ativa ou em erro, resolve para `null` (a UI mostra o estado vazio).
  @action
  Future<void> refreshUltimaAvaliacaoDss() async {
    final gestacao = gestacaoAtual;
    if (gestacao == null) {
      ultimaAvaliacaoDss = null;
      return;
    }
    final result = await avaliacaoDssRepository.list(gestacao.id);
    switch (result) {
      case Success(success: final list):
        ultimaAvaliacaoDss = list.isEmpty ? null : list.first;
      case Error():
        ultimaAvaliacaoDss = null;
    }
  }

  /// Encerra a sessão (revoga o refresh token em melhor esforço) e volta ao
  /// login. Não é `@action`: não muta estado observável.
  Future<void> logout() async {
    final refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await authRepository.logout(refreshToken);
    }
    await tokenStorage.clear();
    _navigateReplacement(routeLogin);
  }
}
