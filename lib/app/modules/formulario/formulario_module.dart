import 'package:flutter_modular/flutter_modular.dart';

import 'controllers/formulario_controller.dart';
import 'formulario_page.dart';
import 'tabs/educacao/educacao_controller.dart';
import 'tabs/trabalho/trabalho_controller.dart';
import 'tabs/saneamento/saneamento_controller.dart';
import 'tabs/saude/saude_controller.dart';
import 'tabs/habitacao/habitacao_controller.dart';
import 'tabs/alimentacao/alimentacao_controller.dart';

class FormularioModule extends Module {
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
