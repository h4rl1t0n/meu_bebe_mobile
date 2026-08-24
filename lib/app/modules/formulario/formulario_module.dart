import 'package:flutter_modular/flutter_modular.dart';

import '../core/core_module.dart';
import 'controllers/formulario_controller.dart';
import 'formulario_page.dart';
import 'submodules/educacao/educacao_controller.dart';
import 'submodules/trabalho/trabalho_controller.dart';
import 'submodules/saneamento/saneamento_controller.dart';
import 'submodules/saude/saude_controller.dart';
import 'submodules/habitacao/habitacao_controller.dart';
import 'submodules/alimentacao/alimentacao_controller.dart';

class FormularioModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void binds(i) {
    i.addSingleton(EducacaoController.new);
    i.addSingleton(TrabalhoController.new);
    i.addSingleton(SaneamentoController.new);
    i.addSingleton(SaudeController.new);
    i.addSingleton(HabitacaoController.new);
    i.addSingleton(AlimentacaoController.new);
    i.addSingleton(FormularioController.new);
  }

  @override
  void routes(r) {
    r.child(Modular.initialRoute, child: (context) => const FormularioPage());
  }
}
