import 'package:flutter/material.dart';

import '../../../../../../model/gestacao/gestacao_model.dart';
import 'current_gestation_page.dart';

/// Converte DUM de DD/MM/AAAA (exibição) para ISO (AAAA-MM-DD), validando data
/// real e rejeitando datas futuras. Retorna `null` se vazio ou inválido.
String? dumDisplayToIso(String? display) {
  final v = (display ?? '').trim();
  if (v.isEmpty) return null;

  final parts = v.split('/');
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;

  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (date.isAfter(today)) return null;

  return '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

/// Converte DUM de ISO (AAAA-MM-DD) para DD/MM/AAAA (exibição).
String dumIsoToDisplay(String? iso) {
  final v = (iso ?? '').trim();
  if (v.isEmpty) return '';
  final parts = v.split('-');
  if (parts.length != 3) return '';
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

mixin CurrentGestationFormController on State<CurrentGestationPage> {
  late final TextEditingController lastMenstrualPeriodEC;
  late final TextEditingController localPreNatalEC;
  late final TextEditingController profissionalPreNatalEC;
  late final TextEditingController contatoLocalPreNatalEC;

  @override
  void initState() {
    super.initState();
    lastMenstrualPeriodEC = TextEditingController();
    localPreNatalEC = TextEditingController();
    profissionalPreNatalEC = TextEditingController();
    contatoLocalPreNatalEC = TextEditingController();
  }

  void disposeControllers() {
    lastMenstrualPeriodEC.dispose();
    localPreNatalEC.dispose();
    profissionalPreNatalEC.dispose();
    contatoLocalPreNatalEC.dispose();
  }

  void initializeForm(GestacaoModel? gestacao) {
    if (gestacao == null) return;
    lastMenstrualPeriodEC.text = dumIsoToDisplay(gestacao.dataUltimaMenstruacao);
    localPreNatalEC.text = gestacao.localPreNatal ?? '';
    profissionalPreNatalEC.text = gestacao.profissionalPreNatal ?? '';
    contatoLocalPreNatalEC.text = gestacao.contatoLocalPreNatal ?? '';
  }
}
