import 'package:flutter_modular/flutter_modular.dart';

import '../../repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import '../../repositories/avaliacao_dss/avaliacao_dss_repository_impl.dart';
import '../../repositories/perfil/perfil_repository.dart';
import '../../repositories/perfil/perfil_repository_impl.dart';
import '../core/core_module.dart';
import 'onboarding_resolver.dart';

/// Expõe o [OnboardingResolver] (e seus repositórios) aos módulos de entrada
/// autenticada: Login, Register e InicializarApp. NÃO define rotas — apenas
/// fornece a resolução de "para onde ir após autenticar".
///
/// Os binds ficam em `exportedBinds` (e NÃO no CoreModule) para que os módulos
/// importadores compartilhem a MESMA instância do resolver, sem re-registrar
/// repositórios de domínio no CoreModule (evita o erro de DI FIX3/FIX4).
class OnboardingModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void exportedBinds(i) {
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<AvaliacaoDssRepository>(AvaliacaoDssRepositoryImpl.new);
    i.addSingleton(OnboardingResolver.new);
  }
}
