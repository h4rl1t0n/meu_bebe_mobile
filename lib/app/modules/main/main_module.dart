import 'package:flutter_modular/flutter_modular.dart';

import '../../core/auth/token_storage.dart';
import '../../repositories/auth/auth_repository.dart';
import '../../repositories/auth/auth_repository_impl.dart';
import '../../repositories/consulta/consulta_repository.dart';
import '../../repositories/consulta/consulta_repository_impl.dart';
import '../../repositories/exame/exame_repository.dart';
import '../../repositories/exame/exame_repository_impl.dart';
import '../../repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import '../../repositories/historico_obstetrico/historico_obstetrico_repository_impl.dart';
import '../../repositories/perfil/perfil_repository.dart';
import '../../repositories/perfil/perfil_repository_impl.dart';
import '../../repositories/plano_parto/plano_parto_repository.dart';
import '../../repositories/plano_parto/plano_parto_repository_impl.dart';
import '../core/core_module.dart';
import 'main_controller.dart';
import 'main_page.dart';
import 'pages/childbirth/childbirth_controller.dart';
import 'pages/gestation/gestation_controller.dart';

class MainModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    // Repositories usados diretamente pelo MainController e pelos controllers
    // das abas resolvidas via Modular.get na MainPage (Gestação e Parto).
    // Demais domínios pertencem aos seus próprios submódulos.
    i.addSingleton<AuthRepository>(AuthRepositoryImpl.new);
    i.addSingleton<TokenStorage>(TokenStorage.new);
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<HistoricoObstetricoRepository>(HistoricoObstetricoRepositoryImpl.new);
    i.addSingleton<ConsultaRepository>(ConsultaRepositoryImpl.new);
    i.addSingleton<ExameRepository>(ExameRepositoryImpl.new);
    // O PlanoPartoRepository vive aqui (e não no CoreModule) porque é o
    // domínio do resumo da aba Parto: a ChildbirthPage é filha direta da
    // MainPage (TabBarView), então o escopo ativo em runtime é o MainModule.
    i.addSingleton<PlanoPartoRepository>(PlanoPartoRepositoryImpl.new);

    i.addSingleton(GestationController.new);
    i.addSingleton(ChildbirthController.new);
    i.addSingleton(MainController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(Modular.initialRoute, child: (context) => MainPage());
  }
}
