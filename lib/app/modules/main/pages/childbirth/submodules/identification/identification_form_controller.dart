import 'package:flutter/material.dart';

import '../../../../../../core/helpers/civil_date.dart';
import '../../../../../../model/gestacao/gestacao_model.dart';
import '../../../../../../model/gestante/gestante_model.dart';
import 'identification_page.dart';

/// Extrai apenas os dígitos (CPF/CNS trafegam normalizados pelo backend).
String digitsOnly(String? value) => (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');

mixin IdentificationFormController on State<IdentificationPage> {
  late final TextEditingController nameEC;
  late final TextEditingController socialNameEC;
  late final TextEditingController birthdayEC;
  late final TextEditingController cpfEC;
  late final TextEditingController nationalHealthCardEC;
  late final TextEditingController prenatalPlaceEC;
  late final TextEditingController profissionalEC;
  late final TextEditingController prenatalPlaceContactEC;

  @override
  void initState() {
    super.initState();
    nameEC = TextEditingController();
    socialNameEC = TextEditingController();
    birthdayEC = TextEditingController();
    cpfEC = TextEditingController();
    nationalHealthCardEC = TextEditingController();
    prenatalPlaceEC = TextEditingController();
    profissionalEC = TextEditingController();
    prenatalPlaceContactEC = TextEditingController();
  }

  void disposeControllers() {
    nameEC.dispose();
    socialNameEC.dispose();
    birthdayEC.dispose();
    cpfEC.dispose();
    nationalHealthCardEC.dispose();
    prenatalPlaceEC.dispose();
    profissionalEC.dispose();
    prenatalPlaceContactEC.dispose();
  }

  /// Preenche o formulário a partir da gestante e da gestação da API.
  void initializeForm(GestanteModel? gestante, GestacaoModel? gestacao) {
    nameEC.text = gestante?.nome ?? '';
    socialNameEC.text = gestante?.nomeSocial ?? '';
    birthdayEC.text = civilDateIsoToDisplay(gestante?.dataNascimento);
    cpfEC.text = digitsOnly(gestante?.cpf);
    nationalHealthCardEC.text = digitsOnly(gestante?.cns);
    prenatalPlaceEC.text = gestacao?.localPreNatal ?? '';
    profissionalEC.text = gestacao?.profissionalPreNatal ?? '';
    prenatalPlaceContactEC.text = gestacao?.contatoLocalPreNatal ?? '';
  }
}
