import 'package:flutter/material.dart';

import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import 'expectations_page.dart';

/// Mixin de formulário de EXPECTATIVAS — persiste STRINGS ESTÁVEIS do backend
/// (nunca ordinal/`.index`). Cada controlador guarda o `value` canônico do enum.
mixin ExpectationsFormController on State<ExpectationsPage> {
  final companionEC = TextEditingController();
  final shaveIntimateHairEC = TextEditingController();
  final bowelWashOrSuppositoryEC = TextEditingController();
  final lowLightEnvironmentEC = TextEditingController();
  final listenToMusicEC = TextEditingController();
  final drinkLiquidsEC = TextEditingController();
  final recordPhotosOrVideosEC = TextEditingController();

  void disposeControllers() {
    companionEC.dispose();
    shaveIntimateHairEC.dispose();
    bowelWashOrSuppositoryEC.dispose();
    lowLightEnvironmentEC.dispose();
    listenToMusicEC.dispose();
    drinkLiquidsEC.dispose();
    recordPhotosOrVideosEC.dispose();
  }

  void initializeForm(PlanoPartoModel? plano) {
    companionEC.text = plano?.acompanhante ?? TriState.naoSei.value;
    shaveIntimateHairEC.text = plano?.rasparPelosIntimos ?? TriState.naoSei.value;
    bowelWashOrSuppositoryEC.text =
        plano?.lavagemIntestinal ?? TriState.naoSei.value;
    lowLightEnvironmentEC.text =
        plano?.ambientePoucaLuz ?? TriState.naoSei.value;
    listenToMusicEC.text = plano?.ouvirMusica ?? TriState.naoSei.value;
    drinkLiquidsEC.text = plano?.beberLiquidos ?? TriState.naoSei.value;
    recordPhotosOrVideosEC.text =
        plano?.registrarFotosVideos ?? TriState.naoSei.value;
  }

  TriState triState(TextEditingController controller) =>
      TriState.fromValue(controller.text);
}
