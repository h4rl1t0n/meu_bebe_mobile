import 'package:flutter/material.dart';

import '../../../../../../model/plano_parto/plano_parto_enums.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import 'birth_moment_page.dart';

/// Mixin de formulário de MOMENTO DO PARTO — persiste STRINGS ESTÁVEIS (nunca
/// ordinal/`.index`). Cada controlador guarda o `value` canônico do enum.
mixin BirthMomentFormController on State<BirthMomentPage> {
  final birthWayEC = TextEditingController();
  final anesthesiaEC = TextEditingController();
  final vaginalCutEC = TextEditingController();
  final preferredPositionEC = TextEditingController();
  final otherPositionEC = TextEditingController();

  void disposeControllers() {
    birthWayEC.dispose();
    anesthesiaEC.dispose();
    vaginalCutEC.dispose();
    preferredPositionEC.dispose();
    otherPositionEC.dispose();
  }

  void initializeForm(PlanoPartoModel? plano) {
    birthWayEC.text = plano?.viaParto ?? ViaParto.naoSei.value;
    anesthesiaEC.text = plano?.anestesia ?? TriState.naoSei.value;
    vaginalCutEC.text = plano?.corteVaginal ?? TriState.naoSei.value;
    preferredPositionEC.text = plano?.posicaoPreferida ?? '';
    otherPositionEC.text = plano?.outraPosicao ?? '';
  }

  ViaParto viaParto() => ViaParto.fromValue(birthWayEC.text);

  TriState triState(TextEditingController controller) =>
      TriState.fromValue(controller.text);

  /// Posição preferida — `null` quando vazio (o campo é opcional no contrato).
  PosicaoParto? position() {
    final v = preferredPositionEC.text.trim();
    return v.isEmpty ? null : PosicaoParto.fromValue(v);
  }
}
