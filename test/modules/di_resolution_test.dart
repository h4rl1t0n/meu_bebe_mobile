import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/core/core_module.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/birth_expectations/birth_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/birth_expectations/birth_module.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/birth_moment/birth_moment_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/birth_moment/birth_moment_module.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/childbirth_resume/childbirth_resume_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/childbirth_resume/childbirth_resume_module.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/desires_expectations/observations_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/desires_expectations/observations_module.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/expectations/expectations_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/expectations/expectations_module.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/identification/identification_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/identification/identification_module.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/pain_relief/pain_relief_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/pain_relief/pain_relief_module.dart';

// `AutoInjector` é o container real por trás de `Module.binds`/`exportedBinds`.
// `modular_core` é a fonte do container e dependência transitiva já presente no
// grafo — uso restrito a este teste de regressão de DI.
// ignore_for_file: depend_on_referenced_packages
import 'package:modular_core/modular_core.dart';

/// Monta um container ÚNICO com o escopo compartilhado ([CoreModule]) + o
/// `binds` do módulo sob teste. Sem `commit()` de propósito: `commit()` chama
/// `startSingletons()` e resolve TODOS os singletons (clientes HTTP, configs),
/// o que aciona efeitos colaterais desnecessários para o teste. Para UM único
/// `AutoInjector`, `get<T>()` resolve o grafo via BFS sobre `injector.binds`
/// diretamente.
T _resolve<T>(Module module) {
  final injector = AutoInjector();
  CoreModule().exportedBinds(injector);
  module.binds(injector);
  return injector.get<T>();
}

void main() {
  group('DI — resolução dos submódulos (FASE 9E-FIX3)', () {
    test('IdentificationModule resolve IdentificationController', () {
      expect(
        _resolve<IdentificationController>(IdentificationModule()),
        isA<IdentificationController>(),
      );
    });

    test('ChildbirthResumeModule resolve ChildbirthResumeController', () {
      expect(
        _resolve<ChildbirthResumeController>(ChildbirthResumeModule()),
        isA<ChildbirthResumeController>(),
      );
    });

    test('ExpectationsModule resolve ExpectationsController', () {
      expect(
        _resolve<ExpectationsController>(ExpectationsModule()),
        isA<ExpectationsController>(),
      );
    });

    test('BirthMomentModule resolve BirthMomentController', () {
      expect(
        _resolve<BirthMomentController>(BirthMomentModule()),
        isA<BirthMomentController>(),
      );
    });

    test('BirthModule resolve BirthController', () {
      expect(
        _resolve<BirthController>(BirthModule()),
        isA<BirthController>(),
      );
    });

    test('PainReliefModule resolve PainReliefController', () {
      expect(
        _resolve<PainReliefController>(PainReliefModule()),
        isA<PainReliefController>(),
      );
    });

    test('ObservationsModule resolve ObservationsController', () {
      expect(
        _resolve<ObservationsController>(ObservationsModule()),
        isA<ObservationsController>(),
      );
    });
  });
}
