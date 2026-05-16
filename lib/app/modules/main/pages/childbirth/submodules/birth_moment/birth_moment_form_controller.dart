import 'package:flutter/material.dart';

import '../../../../../../model/birth_moment.dart';
import 'birth_moment_page.dart';

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

  void initializeForm(BirthMoment? birthMoment) {
    if (birthMoment != null) {
      birthWayEC.text = birthMoment.birthWay.index.toString();
      anesthesiaEC.text = birthMoment.anesthesia.index.toString();
      vaginalCutEC.text = birthMoment.vaginalCut.index.toString();
      birthMoment.preferredPosition == null
          ? preferredPositionEC.clear()
          : preferredPositionEC.text = birthMoment.preferredPosition!.index.toString();
      birthMoment.otherPosition == null
          ? otherPositionEC.clear()
          : otherPositionEC.text = birthMoment.otherPosition!;
    } else {
      birthWayEC.text = '0';
      anesthesiaEC.text = '0';
      vaginalCutEC.text = '0';
      preferredPositionEC.clear();
      otherPositionEC.clear();
    }
  }
}
