import 'package:flutter/material.dart';

import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import 'birth_page.dart';

/// Mixin de formulário de NASCIMENTO — persiste STRINGS ESTÁVEIS (nunca
/// ordinal/`.index`). Cada controlador guarda o `value` canônico do enum.
mixin BirthFormController on State<BirthPage> {
  final whoCutEC = TextEditingController();
  final skinBabyContactEC = TextEditingController();
  final breastfeedFirstHourEC = TextEditingController();
  final firstBathEC = TextEditingController();

  bool collectStemCells = false;
  bool breastfeedRestrictions = false;

  void disposeControllers() {
    whoCutEC.dispose();
    skinBabyContactEC.dispose();
    breastfeedFirstHourEC.dispose();
    firstBathEC.dispose();
  }

  void initializeForm(PlanoPartoModel? plano) {
    whoCutEC.text = plano?.quemCortaCordao ?? ActorChoice.naoSei.value;
    skinBabyContactEC.text = plano?.contatoPeleAPele ?? TriState.naoSei.value;
    breastfeedFirstHourEC.text =
        plano?.amamentarPrimeiraHora ?? TriState.naoSei.value;
    firstBathEC.text = plano?.primeiroBanho ?? ActorChoice.naoSei.value;
    collectStemCells = plano?.coletaCelulasTronco ?? false;
    breastfeedRestrictions = plano?.restricoesAmamentacao ?? false;
  }

  ActorChoice actor(TextEditingController controller) =>
      ActorChoice.fromValue(controller.text);

  TriState triState(TextEditingController controller) =>
      TriState.fromValue(controller.text);
}
