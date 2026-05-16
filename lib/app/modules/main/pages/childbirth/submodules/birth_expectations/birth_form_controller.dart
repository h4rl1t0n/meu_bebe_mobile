import 'package:flutter/material.dart';

import '../../../../../../model/birth.dart';
import 'birth_page.dart';

mixin BirthFormController on State<BirthPage> {
  final whoCutEC = TextEditingController(text: '0');
  final skinBabyContactEC = TextEditingController(text: '0');
  final breastfeedFirstHourEC = TextEditingController(text: '0');
  final firstBathEC = TextEditingController(text: '0');

  bool collectStemCells = false;
  bool breastfeedRestrictions = false;

  void disposeControllers() {
    whoCutEC.dispose();
    skinBabyContactEC.dispose();
    breastfeedFirstHourEC.dispose();
    firstBathEC.dispose();
  }

  void initializeForm(Birth? data) {
    if (data != null) {
      whoCutEC.text = data.whoCut.index.toString();
      skinBabyContactEC.text = data.skinBabyContact.index.toString();
      breastfeedFirstHourEC.text = data.breastfeedFirstHour.index.toString();
      firstBathEC.text = data.firstBath.index.toString();
      collectStemCells = data.collectStemCells;
      breastfeedRestrictions = data.breastfeedRestrictions;
    } else {
      whoCutEC.text = '0';
      skinBabyContactEC.text = '0';
      breastfeedFirstHourEC.text = '0';
      firstBathEC.text = '0';
      collectStemCells = false;
      breastfeedRestrictions = false;
    }
  }
}
