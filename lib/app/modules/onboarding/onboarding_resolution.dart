/// Resultado tipado da resolução do onboarding (FASE 9G-FIX1).
///
/// Substitui o retorno `String` do [OnboardingResolver.resolve], que tratava
/// qualquer falha como `routeTab` (fail-open). Agora cada estado é explícito e
/// a Main só é liberada com [OnboardingComplete].
sealed class OnboardingResolution {
  const OnboardingResolution();
}

/// Onboarding completo: libera a Main (routeTab).
class OnboardingComplete extends OnboardingResolution {
  const OnboardingComplete();
}

/// Próximo passo obrigatório do onboarding: navegar para [route].
class OnboardingNextStep extends OnboardingResolution {
  const OnboardingNextStep(this.route);

  final String route;
}

/// Falha ao consultar o backend (rede/5xx): exibir tela de retry. NÃO libera a
/// Main e NÃO auto-cria gestante/gestação.
class OnboardingFailure extends OnboardingResolution {
  const OnboardingFailure();
}

/// Sessão expirada (401). O AuthInterceptor/SessionManager já navega ao login;
/// aqui é apenas o marcador para NÃO retentar como falha de rede.
class OnboardingSessionExpired extends OnboardingResolution {
  const OnboardingSessionExpired();
}
