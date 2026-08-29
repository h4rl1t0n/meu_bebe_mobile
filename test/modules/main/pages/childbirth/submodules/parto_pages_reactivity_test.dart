import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/core/ui/theme/app_theme.dart';
import 'package:meu_bebe/app/core/ui/theme/styles/colors_app.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/birth_expectations/birth_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/birth_expectations/birth_page.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/birth_moment/birth_moment_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/birth_moment/birth_moment_page.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/expectations/expectations_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/expectations/expectations_page.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/pain_relief/pain_relief_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/pain_relief/pain_relief_page.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:meu_bebe/app/repositories/plano_parto/plano_parto_repository.dart';
import 'package:multiple_result/multiple_result.dart';

import 'plano_parto_test_helpers.dart';

/// Testes de regressão da FASE 9E-FIX5: os dados persistidos das QUATRO seções
/// (Expectativas, Momento do parto, Nascimento, Alívio da dor) devem aparecer na
/// UI AUTOMATICAMENTE após o GET — SEM nenhuma interação do usuário.
///
/// No design antigo, o formulário copiava o `plano` para `TextEditingController`s
/// e bools (não-observáveis) dentro de `initialize().then(...)` + `addPostFrameCallback`,
/// mas nada disparava um rebuild: as abas customizadas liam `controller.text` no
/// `build` SEM nenhum listener (ao contrário do `TextField` usado em Observações).
/// Estes testes falham no design antigo (nenhuma aba marcada / switch falso) e
/// passam após a re-hidratação reativa via `reaction`.

class _ExpectationsScopeModule extends Module {
  _ExpectationsScopeModule(this.perfil, this.planoRepo);

  final PerfilRepository perfil;
  final PlanoPartoRepository planoRepo;

  @override
  void binds(Injector i) {
    i.addInstance<PerfilRepository>(perfil);
    i.addInstance<PlanoPartoRepository>(planoRepo);
    i.addSingleton(ExpectationsController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const ExpectationsPage());
  }
}

class _BirthMomentScopeModule extends Module {
  _BirthMomentScopeModule(this.perfil, this.planoRepo);

  final PerfilRepository perfil;
  final PlanoPartoRepository planoRepo;

  @override
  void binds(Injector i) {
    i.addInstance<PerfilRepository>(perfil);
    i.addInstance<PlanoPartoRepository>(planoRepo);
    i.addSingleton(BirthMomentController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const BirthMomentPage());
  }
}

class _BirthScopeModule extends Module {
  _BirthScopeModule(this.perfil, this.planoRepo);

  final PerfilRepository perfil;
  final PlanoPartoRepository planoRepo;

  @override
  void binds(Injector i) {
    i.addInstance<PerfilRepository>(perfil);
    i.addInstance<PlanoPartoRepository>(planoRepo);
    i.addSingleton(BirthController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const BirthPage());
  }
}

class _PainReliefScopeModule extends Module {
  _PainReliefScopeModule(this.perfil, this.planoRepo);

  final PerfilRepository perfil;
  final PlanoPartoRepository planoRepo;

  @override
  void binds(Injector i) {
    i.addInstance<PerfilRepository>(perfil);
    i.addInstance<PlanoPartoRepository>(planoRepo);
    i.addSingleton(PainReliefController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const PainReliefPage());
  }
}

Widget _mount(Module module, Widget page) {
  // Usamos `MaterialApp(home:)` (sem o `Modular.routerConfig` global) para que
  // cada teste tenha uma árvore de navegação isolada. O `Modular.routerConfig`
  // é um singleton cujo `RouterDelegate`/`Navigator` vazam estado entre
  // `testWidgets` com módulos diferentes, reaproveitando a página do teste
  // anterior.
  return ModularApp(
    module: module,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: page,
    ),
  );
}

/// Conta as abas (custom `InkWell`+`Container`) cujo rótulo é [label] e cuja
/// cor de destaque (`secondary`) indica que estão SELECIONADAS. Uma aba é
/// selecionada quando `controller.text == value.value` no último build.
int _selectedTabs(WidgetTester tester, String label) {
  final finder = find.ancestor(
    of: find.text(label),
    matching: find.byType(InkWell),
  );
  var count = 0;
  for (final ink in tester.widgetList<InkWell>(finder)) {
    final child = ink.child;
    if (child is Container &&
        child.decoration is BoxDecoration &&
        (child.decoration as BoxDecoration).color == ColorsApp.instance.secondary) {
      count++;
    }
  }
  return count;
}

void main() {
  group('FASE 9E-FIX5 — dados aparecem sem interação', () {
    testWidgets('Expectativas: marca "Sim" do acompanhante automaticamente', (tester) async {
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(acompanhante: 'sim'),
        ),
      );

      await tester.pumpWidget(
        _mount(_ExpectationsScopeModule(perfil, planoRepo), const ExpectationsPage()),
      );
      await tester.pumpAndSettle();

      // 1 aba "Sim" (acompanhante), 0 "Não" e 6 "Não sei" (as demais) selecionadas.
      expect(_selectedTabs(tester, 'Sim'), 1);
      expect(_selectedTabs(tester, 'Não'), 0);
      expect(_selectedTabs(tester, 'Não sei'), 6);
    });

    testWidgets('Momento do parto: marca "Cesárea" da via de parto automaticamente', (tester) async {
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(viaParto: 'cesarea'),
        ),
      );

      await tester.pumpWidget(
        _mount(_BirthMomentScopeModule(perfil, planoRepo), const BirthMomentPage()),
      );
      await tester.pumpAndSettle();

      expect(_selectedTabs(tester, 'Cesárea'), 1);
      expect(_selectedTabs(tester, 'Vaginal'), 0);
    });

    testWidgets('Nascimento: liga "Coleta de células-tronco" e marca "Sim" automaticamente', (tester) async {
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(
            coletaCelulasTronco: true,
            contatoPeleAPele: 'sim',
          ),
        ),
      );

      await tester.pumpWidget(
        _mount(_BirthScopeModule(perfil, planoRepo), const BirthPage()),
      );
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Coleta de células-tronco?'),
      );
      expect(switchTile.value, isTrue);
      expect(_selectedTabs(tester, 'Sim'), 1);
    });

    testWidgets('Alívio da dor: mostra métodos e marca "Massagem" automaticamente', (tester) async {
      final perfil = FakePerfilRepository(
        onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
      );
      final planoRepo = FakePlanoPartoRepository(
        onGet: (_) async => Success<PlanoPartoModel?, BackendFailure>(
          PlanoPartoModel.empty().copyWith(
            querAlivioDor: 'sim',
            massagem: true,
          ),
        ),
      );

      await tester.pumpWidget(
        _mount(_PainReliefScopeModule(perfil, planoRepo), const PainReliefPage()),
      );
      await tester.pumpAndSettle();

      // Seção de métodos só renderiza quando "quer alívio da dor" == "sim".
      expect(find.text('Quais métodos você prefere?'), findsOneWidget);
      final checkbox = tester.widget<CheckboxListTile>(
        find.widgetWithText(CheckboxListTile, 'Massagem'),
      );
      expect(checkbox.value, isTrue);
      expect(_selectedTabs(tester, 'Sim'), 1);
    });
  });
}
