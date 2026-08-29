import 'package:flutter_modular/flutter_modular.dart';

/// Chave do argumento de rota que sinaliza o fluxo de ONBOARDING (primeiro
/// acesso). O app não usa `Modular.args` em lugar nenhum além daqui, então o
/// argumento é o único canal para distinguir "onboarding" de "uso normal" nas
/// telas reutilizadas (Dados da gestante, Gravidez atual e Formulário DSS).
const onboardingArgsKey = 'onboarding';

/// Argumentos a passar em `pushNamed/pushReplacementNamed` para marcar uma
/// navegação como parte do onboarding.
Map<String, Object> get onboardingArgs => const {onboardingArgsKey: true};

/// Lê o modo onboarding da rota atual.
bool isOnboardingRoute() {
  final data = Modular.args.data;
  return data is Map && data[onboardingArgsKey] == true;
}
