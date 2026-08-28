import 'package:flutter_modular/flutter_modular.dart';

import '../../core/auth/token_storage.dart';
import '../../repositories/appointments/appointments_repository.dart';
import '../../repositories/auth/auth_repository.dart';
import '../../repositories/auth/auth_repository_impl.dart';
import '../../repositories/perfil/perfil_repository.dart';
import '../../repositories/perfil/perfil_repository_impl.dart';
import '../core/core_module.dart';
import '../../repositories/appointments/appointments_repository_sqlite.dart';
import '../../repositories/birth/birth_repository.dart';
import '../../repositories/birth/birth_repository_impl.dart';
import '../../repositories/birth_moment/birth_moment_repository.dart';
import '../../repositories/birth_moment/birth_moment_repository_impl.dart';
import '../../repositories/exams/exams_repository.dart';
import '../../repositories/exams/exams_repository_sqlite.dart';
import '../../repositories/expectations/expectations_repository.dart';
import '../../repositories/expectations/expectations_repository_impl.dart';
import '../../repositories/gestation/gestation_repository.dart';
import '../../repositories/gestation/gestation_repository_impl.dart';
import '../../repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import '../../repositories/historico_obstetrico/historico_obstetrico_repository_impl.dart';
import '../../repositories/medication/medication_repository.dart';
import '../../repositories/medication/medication_repository_impl.dart';
import '../../repositories/observations/observations_repository.dart';
import '../../repositories/observations/observations_repository_impl.dart';
import '../../repositories/pain_relief/pain_relief_repository.dart';
import '../../repositories/pain_relief/pain_relief_repository_impl.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../repositories/profile/profile_repository_impl.dart';
import '../../repositories/vaccines/vaccines_repository.dart';
import '../../repositories/vaccines/vaccines_repository_impl.dart';
import 'main_controller.dart';
import 'main_page.dart';
import 'pages/childbirth/submodules/childbirth_resume/childbirth_resume_controller.dart';
import 'pages/childbirth/submodules/expectations/expectations_controller.dart';
import 'pages/childbirth/submodules/identification/identification_controller.dart';
import 'pages/gestation/gestation_controller.dart';
import 'pages/home/submodules/medication/medication_controller.dart';
import 'pages/home/submodules/vaccines/vaccines_controller.dart';
import 'pages/profile/submodules/profile_data/profile_data_controller.dart';

class MainModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton<AuthRepository>(AuthRepositoryImpl.new);
    i.addSingleton<TokenStorage>(TokenStorage.new);
    i.addSingleton<PerfilRepository>(PerfilRepositoryImpl.new);
    i.addSingleton<GestationRepository>(GestationRepositoryImpl.new);
    i.addSingleton<ProfileRepository>(ProfileRepositoryImpl.new);
    i.addSingleton<VaccinesRepository>(VaccinesRepositoryImpl.new);
    i.addSingleton<MedicationRepository>(MedicationRepositoryImpl.new);
    i.addSingleton<HistoricoObstetricoRepository>(HistoricoObstetricoRepositoryImpl.new);
    i.addSingleton<ExpectationsRepository>(ExpectationsRepositoryImpl.new);
    i.addSingleton<AppointmentsRepository>(AppointmentsRepositoryImpl.new);
    i.addSingleton<ExamsRepository>(ExamsRepositoryImpl.new);
    i.addSingleton<BirthMomentRepository>(BirthMomentRepositoryImpl.new);
    i.addSingleton<BirthRepository>(BirthRepositoryImpl.new);
    i.addSingleton<PainReliefRepository>(PainReliefRepositoryImpl.new);
    i.addSingleton<ObservationsRepository>(ObservationsRepositoryImpl.new);

    i.addSingleton(GestationController.new);
    i.addSingleton(ChildbirthResumeController.new);
    i.addSingleton(VaccinesController.new);
    i.addSingleton(MedicationController.new);
    i.addSingleton(ProfileDataController.new);
    i.addSingleton(ExpectationsController.new);
    i.addSingleton(IdentificationController.new);
    i.addSingleton(MainController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(Modular.initialRoute, child: (context) => MainPage());
  }
}
