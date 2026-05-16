import 'package:flutter/material.dart';

mixin FormTextController<T extends StatefulWidget> on State<T> {
  late final TextEditingController nameEC;
  late final TextEditingController dateEC;
  late final TextEditingController descriptionEC;

  @override
  void initState() {
    super.initState();
    nameEC = TextEditingController();
    dateEC = TextEditingController();
    descriptionEC = TextEditingController();
  }

  void disposeControllers() {
    nameEC.dispose();
    dateEC.dispose();
    descriptionEC.dispose();
  }

  void clearControllers() {
    nameEC.clear();
    dateEC.clear();
    descriptionEC.clear();
  }
}
