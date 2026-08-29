import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/core/core_module.dart';
import 'package:meu_bebe/app/repositories/plano_parto/plano_parto_repository.dart';

// `AutoInjector` não é reexportado pelo `flutter_modular` (o `show` daquela
// biblioteca exclui a classe), embora seja o container que os `Module`s usam.
// `modular_core` é a fonte real do container e é dependência transitiva já
// presente no grafo — uso restrito a este teste de regressão de DI.
// ignore_for_file: depend_on_referenced_packages
import 'package:modular_core/modular_core.dart';

void main() {
  test(
    'CoreModule.exportedBinds expõe infraestrutura global (DioForNative)',
    () {
      final injector = AutoInjector();
      CoreModule().exportedBinds(injector);

      // `DioForNative` é a dependência transversal que todos os repositories
      // HTTP (e, indiretamente, seus controllers) resolvem. Sem ela no escopo
      // compartilhado, nenhum submódulo consegue construir seus repositories.
      expect(injector.isAdded<DioForNative>(), isTrue);
    },
  );

  test(
    'CoreModule.exportedBinds NÃO registra repositório de domínio '
    '(PlanoPartoRepository)',
    () {
      final injector = AutoInjector();
      CoreModule().exportedBinds(injector);

      // Regressão FASE 9E-FIX3: `PlanoPartoRepository` é específico do domínio
      // Plano de Parto e deve viver SOMENTE nos módulos que o usam (seções +
      // resumo). Promovê-lo ao CoreModule tornaria o escopo global indevidamente
      // acoplado a um domínio — exatamente o que a FIX3 removeu.
      expect(injector.isAdded<PlanoPartoRepository>(), isFalse);
    },
  );
}
