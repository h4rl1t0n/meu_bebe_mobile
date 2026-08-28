import 'package:flutter/material.dart';

import '../../../../../../model/gestante/gestante_model.dart';

/// Extrai apenas os dígitos (CPF/CNS trafegam normalizados pelo backend).
String digitsOnly(String? value) => (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');

/// `YYYY-MM-DD` (backend) → `DD/MM/YYYY` (exibição no formulário).
String dateToDisplay(String? iso) {
  final v = iso ?? '';
  final parts = v.split('-');
  if (parts.length != 3) return v;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

/// `DD/MM/YYYY` (formulário) → `YYYY-MM-DD` (backend). `null` se inválida.
String? dateToIso(String? display) {
  final v = (display ?? '').trim();
  if (v.isEmpty) return null;
  final parts = v.split('/');
  if (parts.length != 3) return null;
  final d = parts[0].padLeft(2, '0');
  final m = parts[1].padLeft(2, '0');
  final y = parts[2].padLeft(4, '0');
  return '$y-$m-$d';
}

/// Controladores do formulário de dados da gestante (fonte de verdade: backend).
mixin ProfileFormController {
  final nameEC = TextEditingController();
  final socialNameEC = TextEditingController();
  final birthdayEC = TextEditingController();
  final cpfEC = TextEditingController();
  final cnsEC = TextEditingController();
  final emailEC = TextEditingController();

  void disposeControllers() {
    nameEC.dispose();
    socialNameEC.dispose();
    birthdayEC.dispose();
    cpfEC.dispose();
    cnsEC.dispose();
    emailEC.dispose();
  }

  void initializeForm(GestanteModel? gestante, String? email) {
    if (gestante != null) {
      nameEC.text = gestante.nome;
      socialNameEC.text = gestante.nomeSocial ?? '';
      birthdayEC.text = dateToDisplay(gestante.dataNascimento);
      cpfEC.text = digitsOnly(gestante.cpf);
      cnsEC.text = digitsOnly(gestante.cns);
    }
    emailEC.text = email ?? '';
  }
}
