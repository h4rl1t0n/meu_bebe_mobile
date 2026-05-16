import 'package:flutter/material.dart';

import '../../../../../../model/observations.dart';
import 'observations_page.dart';

mixin ObservationsFormController on State<ObservationsPage> {
  final observationsEC = TextEditingController();

  void disposeControllers() {
    observationsEC.dispose();
  }

  void initializeForm(Observations? data) {
    if (data != null) {
      observationsEC.text = data.observations;
    } else {
      observationsEC.clear();
    }
  }
}
