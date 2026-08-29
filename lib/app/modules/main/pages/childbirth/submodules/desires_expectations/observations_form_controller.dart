import 'package:flutter/material.dart';

import '../../../../../../model/plano_parto/plano_parto_model.dart';
import 'observations_page.dart';

/// Mixin de formulário de OBSERVAÇÕES — a seção é apenas o campo de texto
/// `observacoes` do plano consolidado.
mixin ObservationsFormController on State<ObservationsPage> {
  final observationsEC = TextEditingController();

  void disposeControllers() {
    observationsEC.dispose();
  }

  void initializeForm(PlanoPartoModel? plano) {
    observationsEC.text = plano?.observacoes ?? '';
  }
}
