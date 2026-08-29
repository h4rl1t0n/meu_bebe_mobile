import 'package:flutter/material.dart';

import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import 'pain_relief_page.dart';

/// Mixin de formulário de ALÍVIO DA DOR — persiste STRINGS ESTÁVEIS (nunca
/// ordinal/`.index`). O "quer alívio da dor" guarda o `value` do enum.
mixin PainReliefFormController on State<PainReliefPage> {
  final painReliefEC = TextEditingController();

  bool massage = false;
  bool ballExercises = false;
  bool breathRelaxExercises = false;
  bool showerBath = false;
  bool bathtubBath = false;
  bool acupuncture = false;
  bool acupressure = false;
  bool otherMethod = false;

  void disposeControllers() {
    painReliefEC.dispose();
  }

  void initializeForm(PlanoPartoModel? plano) {
    painReliefEC.text = plano?.querAlivioDor ?? TriState.naoSei.value;
    massage = plano?.massagem ?? false;
    ballExercises = plano?.exerciciosBola ?? false;
    breathRelaxExercises = plano?.exerciciosRespiracao ?? false;
    showerBath = plano?.banhoChuveiro ?? false;
    bathtubBath = plano?.banhoBanheira ?? false;
    acupuncture = plano?.acupuntura ?? false;
    acupressure = plano?.acupressao ?? false;
    otherMethod = plano?.outroMetodo ?? false;
  }

  TriState triState() => TriState.fromValue(painReliefEC.text);
}
