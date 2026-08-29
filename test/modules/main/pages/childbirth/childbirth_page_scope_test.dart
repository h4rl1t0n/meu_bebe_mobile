import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/ui/theme/app_theme.dart';
import 'package:meu_bebe/app/model/plano_parto/plano_parto_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/childbirth_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/childbirth_page.dart';
import 'package:meu_bebe/app/repositories/perfil/perfil_repository.dart';
import 'package:meu_bebe/app/repositories/plano_parto/plano_parto_repository.dart';
import 'package:multiple_result/multiple_result.dart';

import 'submodules/plano_parto_test_helpers.dart';

/// Reproduz o escopo REAL de runtime da aba Parto, replicando as dependências
/// que o [MainModule] agora registra: `PerfilRepository` + `PlanoPartoRepository`
/// + `ChildbirthController` (o controller do escopo pai). NÃO registra o
/// `ChildbirthResumeController`, que pertence ao `ChildbirthResumeModule`
/// (rota irmã) — exatamente a situação que produzia o `UnregisteredInstance`.
///
/// No design antigo, `ChildbirthResumeCard` fazia
/// `Modular.get<ChildbirthResumeController>()` dentro da aba Parto; como o
/// módulo irmão não está ativo, a montagem da `ChildbirthPage` lançava
/// `UnregisteredInstance`. Este teste monta a página em contexto real e exige
/// que ela construa SEM exceção.
class _PartoScopeModule extends Module {
  _PartoScopeModule(this.perfilRepository, this.planoPartoRepository);

  final PerfilRepository perfilRepository;
  final PlanoPartoRepository planoPartoRepository;

  @override
  void binds(Injector i) {
    i.addInstance<PerfilRepository>(perfilRepository);
    i.addInstance<PlanoPartoRepository>(planoPartoRepository);
    i.addSingleton(ChildbirthController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(Modular.initialRoute, child: (context) => const ChildbirthPage());
  }
}

Widget _mount(Module module) {
  return ModularApp(
    module: module,
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: Modular.routerConfig,
    ),
  );
}

void main() {
  group('ChildbirthPage — escopo real da aba Parto (FASE 9E-FIX4)', () {
    testWidgets(
      'monta a aba sem UnregisteredInstance mesmo sem ChildbirthResumeModule ativo',
      (tester) async {
        final perfil = FakePerfilRepository(
          onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
        );
        final planoParto = FakePlanoPartoRepository(
          onGet: (id) async => Success(PlanoPartoModel.empty()),
        );

        await tester.pumpWidget(
          _mount(_PartoScopeModule(perfil, planoParto)),
        );
        await tester.pumpAndSettle();

        // Se o card ainda resolvesse `ChildbirthResumeController`, a montagem
        // teria lançado `UnregisteredInstance` antes de chegar aqui.
        expect(tester.takeException(), isNull);
        expect(find.text('Resumo do plano de parto'), findsOneWidget);
        expect(find.text('Visualizar'), findsOneWidget);
      },
    );

    testWidgets(
      'card exibe o plano carregado pelo controller pai (dados por parâmetro)',
      (tester) async {
        final perfil = FakePerfilRepository(
          onGetGestacaoAtual: () async => gestacaoResult(gestacaoAtiva),
        );
        final planoParto = FakePlanoPartoRepository(
          onGet: (id) async => Success(
            PlanoPartoModel.empty().copyWith(viaParto: 'vaginal'),
          ),
        );

        await tester.pumpWidget(
          _mount(_PartoScopeModule(perfil, planoParto)),
        );
        await tester.pumpAndSettle();

        // `viaParto == 'vaginal'` → label "Vaginal" via ViaParto.fromValue.
        expect(find.text('Vaginal'), findsOneWidget);
      },
    );

    testWidgets(
      'sem gestação ativa o card renderiza "Não definido" sem quebrar',
      (tester) async {
        final perfil = FakePerfilRepository(); // getGestacaoAtual → Success(null)
        final planoParto = FakePlanoPartoRepository();

        await tester.pumpWidget(
          _mount(_PartoScopeModule(perfil, planoParto)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Resumo do plano de parto'), findsOneWidget);
        expect(find.text('Não definido'), findsWidgets);
      },
    );
  });
}
