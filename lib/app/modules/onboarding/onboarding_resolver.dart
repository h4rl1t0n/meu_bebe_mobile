import 'package:multiple_result/multiple_result.dart';

import '../../app_module.dart';
import '../../core/fp/backend_failure.dart';
import '../../model/gestacao/gestacao_model.dart';
import '../../repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import '../../repositories/perfil/perfil_repository.dart';
import 'onboarding_resolution.dart';

/// Resolve o destino pós-autenticação a partir do estado REAL do backend
/// (FASE 9G-FIX1). NÃO usa `bool primeiroAcesso` em SharedPreferences nem a
/// probabilidade da estimativa: a existência de gestante, gestação ativa e
/// avaliação DSS persistida (GET list) é que determina o próximo passo.
///
/// Ordem de resolução:
///  1. sem gestante        → [OnboardingNextStep] routeDadosPerfil
///  2. sem gestação ativa  → [OnboardingNextStep] routeGravidezAtual
///  3. sem avaliação DSS   → [OnboardingNextStep] routeForm
///  4. caso contrário      → [OnboardingComplete]
///
/// FALHA FECHADA (fail-closed): qualquer [Error] vira [OnboardingFailure]
/// (rede/5xx) ou [OnboardingSessionExpired] (401). A Main NUNCA é liberada por
/// erro — a sessão expirada é tratada a jusante pelo AuthInterceptor/
/// SessionManager (que já navega ao login).
class OnboardingResolver {
  final PerfilRepository perfilRepository;
  final AvaliacaoDssRepository avaliacaoDssRepository;

  OnboardingResolver(this.perfilRepository, this.avaliacaoDssRepository);

  OnboardingResolution? _cached;

  /// Resolve de novo (consulta o backend) e atualiza o cache.
  Future<OnboardingResolution> resolve() async {
    final resolution = await _compute();
    _cached = resolution;
    return resolution;
  }

  /// Resolução reutilizável: retorna o resultado em cache, consultando o
  /// backend apenas se ainda não houver um. Usada pelo guard da Main para não
  /// duplicar as 3 requisições já feitas na entrada.
  Future<OnboardingResolution> resolveCached() async {
    return _cached ??= await _compute();
  }

  /// Descarta o resultado em cache (após persistir o primeiro DSS), para que a
  /// próxima verificação re-consulte o backend e libere a Main.
  void invalidate() {
    _cached = null;
  }

  Future<OnboardingResolution> _compute() async {
    switch (await perfilRepository.getGestante()) {
      case Error(error: final failure):
        return _failureFor(failure);
      case Success(success: null):
        return const OnboardingNextStep(routeDadosPerfil);
      case Success():
        break;
    }

    switch (await perfilRepository.getGestacaoAtual()) {
      case Error(error: final failure):
        return _failureFor(failure);
      case Success(success: null):
        return const OnboardingNextStep(routeGravidezAtual);
      case Success(success: final GestacaoModel gestacao):
        switch (await avaliacaoDssRepository.list(gestacao.id)) {
          case Error(error: final failure):
            return _failureFor(failure);
          case Success(success: final avaliacoes):
            return avaliacoes.isEmpty
                ? const OnboardingNextStep(routeForm)
                : const OnboardingComplete();
        }
    }
  }

  OnboardingResolution _failureFor(BackendFailure failure) {
    if (failure is SessionExpiredFailure) {
      return const OnboardingSessionExpired();
    }
    return const OnboardingFailure();
  }
}
