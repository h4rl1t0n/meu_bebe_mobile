import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/auth/token_storage.dart';
import 'package:meu_bebe/app/core/ui/theme/app_theme.dart';
import 'package:meu_bebe/app/modules/onboarding/onboarding_resolution.dart';
import 'package:meu_bebe/app/modules/onboarding/onboarding_resolver.dart';
import 'package:meu_bebe/app/modules/register/register_controller.dart';
import 'package:meu_bebe/app/modules/register/register_page.dart';
import 'package:meu_bebe/app/repositories/auth/auth_repository.dart';
import 'package:meu_bebe/app/repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Testes de REATIVIDADE do obscureText na tela de cadastro (FASE 9J).
///
/// Provam que o toque no olho alterna `obscureText` e o ícone IMEDIATAMENTE
/// via MobX, sem depender de `setState` — a regressão original (item 46/50 da
/// diretiva) era exatamente o campo não reagir ao toque.

class _NoopAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopPerfilRepository implements PerfilRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAvaliacaoDssRepository implements AvaliacaoDssRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubOnboardingResolver extends OnboardingResolver {
  _StubOnboardingResolver() : super(_NoopPerfilRepository(), _NoopAvaliacaoDssRepository());

  @override
  Future<OnboardingResolution> resolve() async => const OnboardingComplete();
}

class _RegisterScopeModule extends Module {
  _RegisterScopeModule(this.controller);

  final RegisterController controller;

  @override
  void binds(Injector i) {
    i.addInstance<RegisterController>(controller);
  }

  @override
  void routes(RouteManager r) {
    r.child(Modular.initialRoute, child: (context) => const RegisterPage());
  }
}

Widget _mount(RegisterController controller) {
  return ModularApp(
    module: _RegisterScopeModule(controller),
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: Modular.routerConfig,
    ),
  );
}

/// Estados de obscureText na ordem de construção: e-mail, senha, confirmação.
///
/// `TextFormField` não expõe `obscureText` como getter público — ele repassa a
/// propriedade ao `TextField` interno, então lemos deste último.
List<bool> _obscureStates(WidgetTester tester) => tester
    .widgetList<TextField>(find.byType(TextField))
    .map((f) => f.obscureText)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  RegisterController makeController() => RegisterController(
        _NoopAuthRepository(),
        const TokenStorage(),
        _StubOnboardingResolver(),
      );

  group('RegisterPage — obscureText reativo (FASE 9J)', () {
    testWidgets('senha e confirmação iniciam ocultas com ícone visibility', (tester) async {
      await tester.pumpWidget(_mount(makeController()));
      await tester.pumpAndSettle();

      // e-mail (false) + senha (true) + confirmar senha (true).
      expect(_obscureStates(tester), [false, true, true]);
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });

    testWidgets('tap no olho da senha alterna obscureText e o ícone imediatamente', (tester) async {
      await tester.pumpWidget(_mount(makeController()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.visibility).first);
      await tester.pump();

      expect(_obscureStates(tester), [false, false, true]);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off).first);
      await tester.pump();

      expect(_obscureStates(tester), [false, true, true]);
      expect(find.byIcon(Icons.visibility), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });

    testWidgets('confirmar senha alterna de forma independente', (tester) async {
      await tester.pumpWidget(_mount(makeController()));
      await tester.pumpAndSettle();

      // O segundo olho é o da confirmação.
      await tester.tap(find.byIcon(Icons.visibility).at(1));
      await tester.pump();

      expect(_obscureStates(tester), [false, true, false]);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}
