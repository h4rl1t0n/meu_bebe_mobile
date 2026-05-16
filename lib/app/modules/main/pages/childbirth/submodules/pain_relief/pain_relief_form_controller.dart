import 'package:flutter/material.dart';

import '../../../../../../model/pain_relief.dart';
import 'pain_relief_page.dart';

mixin PainReliefFormController on State<PainReliefPage> {
  final painReliefEC = TextEditingController(text: '0');

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

  void initializeForm(PainRelief? data) {
    if (data != null) {
      painReliefEC.text = data.painRelief.index.toString();
      massage = data.massage;
      ballExercises = data.ballExercises;
      breathRelaxExercises = data.breathRelaxExercises;
      showerBath = data.showerBath;
      bathtubBath = data.bathtubBath;
      acupuncture = data.acupuncture;
      acupressure = data.acupressure;
      otherMethod = data.otherMethod;
    } else {
      painReliefEC.text = '0';
      massage = false;
      ballExercises = false;
      breathRelaxExercises = false;
      showerBath = false;
      bathtubBath = false;
      acupuncture = false;
      acupressure = false;
      otherMethod = false;
    }
  }
}
