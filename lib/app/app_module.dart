import 'package:flutter_modular/flutter_modular.dart';

import 'modules/core/core_module.dart';
import 'modules/formulario/formulario_module.dart';
import 'modules/inicializar_app/inicializar_app_module.dart';
import 'modules/login/login_module.dart';
import 'modules/register/register_module.dart';
import 'modules/main/pages/childbirth/submodules/birth_moment/birth_moment_module.dart';
import 'modules/main/pages/childbirth/submodules/pain_relief/pain_relief_module.dart';
import 'modules/main/pages/childbirth/submodules/birth_expectations/birth_module.dart';
import 'modules/main/pages/childbirth/submodules/desires_expectations/observations_module.dart';
import 'modules/main/pages/childbirth/submodules/childbirth_resume/childbirth_resume_module.dart';
import 'modules/main/pages/childbirth/submodules/current_gestation/current_gestation_module.dart';
import 'modules/main/pages/childbirth/submodules/expectations/expectations_module.dart';
import 'modules/main/pages/childbirth/submodules/history/history_module.dart';
import 'modules/main/pages/childbirth/submodules/identification/identification_module.dart';
import 'modules/main/pages/home/submodules/appointments_exams/appointments_exams_module.dart';
import 'modules/main/pages/home/submodules/information/information_module.dart';
import 'modules/main/pages/home/submodules/medication/medication_module.dart';
import 'modules/main/pages/home/submodules/vaccines/vaccines_module.dart';
import 'modules/main/main_module.dart';
import 'modules/main/pages/profile/submodules/configuracoes/configuracoes_module.dart';
import 'modules/main/pages/profile/submodules/notificacoes/notificacoes_module.dart';
import 'modules/main/pages/profile/submodules/profile_data/profile_data_module.dart';
import 'modules/main/pages/profile/submodules/sobre_app/sobre_app_module.dart';

class AppModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void routes(r) {
    r.module(Modular.initialRoute, module: InicializarAppModule());
    r.module(routeLogin, module: LoginModule());
    r.module(routeRegister, module: RegisterModule());
    r.module(routeForm, module: FormularioModule());
    r.module(routeTab, module: MainModule());

    // Module da Tab Home
    r.module(routeConsultasExames, module: AppointmentsExamsModule());
    r.module(routeInformacoes, module: InformationModule());
    r.module(routeMedicacoes, module: MedicationModule());
    r.module(routeVacinas, module: VaccinesModule());

    // Module da Tab Gestação

    // Module da Tab Plano de Parto
    r.module(routeIndetificacao, module: IdentificationModule());
    r.module(routeHistoria, module: HistoryModule());
    r.module(routeExpectativa, module: ExpectationsModule());
    r.module(routeGravidezAtual, module: CurrentGestationModule());
    r.module(routeMomentoParto, module: BirthMomentModule());
    r.module(routeAlivioDor, module: PainReliefModule());
    r.module(routeNascimento, module: BirthModule());
    r.module(routeObservacoes, module: ObservationsModule());
    r.module(routeVisualizarResumo, module: ChildbirthResumeModule());

    // Module da Tab Perfil
    r.module(routeDadosPerfil, module: ProfileDataModule());
    r.module(routeNotificacoes, module: NotificacoesModule());
    r.module(routeConfiguracoes, module: ConfiguracoesModule());
    r.module(routeSobreApp, module: SobreAppModule());
  }
}

const routeLogin = '/login/';
const routeRegister = '/register/';
const routeForm = '/form/';
const routeTab = '/tab/';

const routeConsultasExames = '/consultas_exames/';
const routeInformacoes = '/informacoes/';
const routeMedicacoes = '/medicacoes/';
const routeVacinas = '/vacinas/';

const routeIndetificacao = '/indetificacao/';
const routeHistoria = '/historia/';
const routeExpectativa = '/expectativa/';
const routeGravidezAtual = '/gravizez_atual/';
const routeVisualizarResumo = '/visualizar_resumo/';

const routeDadosPerfil = '/dados_perfil/';
const routeNotificacoes = '/notificacoes/';
const routeConfiguracoes = '/configuracoes/';
const routeSobreApp = '/sobre_app/';

const routeMomentoParto = '/momento_parto/';
const routeAlivioDor = '/alivio_dor/';
const routeNascimento = '/nascimento/';
const routeObservacoes = '/observacoes/';

const routeUpdateChildbirth = '/update_childbirth/';
