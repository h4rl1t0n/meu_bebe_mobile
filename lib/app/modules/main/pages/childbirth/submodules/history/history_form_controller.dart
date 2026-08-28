import 'package:flutter/material.dart';

import '../../../../../../model/historico_obstetrico/historico_obstetrico_model.dart';
import 'history_page.dart';

mixin HistoryFormController on State<HistoryPage> {
  final pregnantNumberEC = TextEditingController();
  final childbirthNumberEC = TextEditingController();
  final abortionNumberEC = TextEditingController();

  void disposeControllers() {
    pregnantNumberEC.dispose();
    childbirthNumberEC.dispose();
    abortionNumberEC.dispose();
  }

  void initializeForm(HistoricoObstetricoModel? historico) {
    pregnantNumberEC.text = historico?.pregnancyNumber?.toString() ?? '';
    childbirthNumberEC.text = historico?.givenBirthNumber?.toString() ?? '';
    abortionNumberEC.text = historico?.abortionsNumber?.toString() ?? '';
  }
}
