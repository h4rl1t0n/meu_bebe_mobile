import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:meu_bebe/app/core/ui/theme/app_theme.dart';
import 'package:meu_bebe/app/modules/main/pages/home/submodules/kick_counter/kick_counter_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/home/submodules/kick_counter/kick_counter_module.dart';
import 'package:meu_bebe/app/modules/main/pages/home/submodules/kick_counter/kick_counter_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _mount() {
  return ModularApp(
    module: KickCounterModule(),
    child: MaterialApp(theme: AppTheme.lightTheme, home: const KickCounterPage()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Modular.destroy();
  });

  testWidgets('renderiza AppBar, contador e botão de chute', (tester) async {
    await tester.pumpWidget(_mount());
    await tester.pumpAndSettle();

    expect(find.text('Contador de Movimentos'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('de 10 chutes'), findsOneWidget);
    expect(find.text('Chute!'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);
    expect(find.text('Reiniciar'), findsOneWidget);
    expect(find.text('Histórico de sessões'), findsOneWidget);
  });

  testWidgets('incrementa contagem ao tocar no botão Chute!', (tester) async {
    await tester.pumpWidget(_mount());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chute!'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
  });

  testWidgets('abre orientações clínicas ao tocar no ícone de info', (tester) async {
    await tester.pumpWidget(_mount());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('Como funciona o monitoramento?'), findsOneWidget);
    expect(find.text('Entendi'), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();

    expect(find.text('Como funciona o monitoramento?'), findsNothing);
  });
}
