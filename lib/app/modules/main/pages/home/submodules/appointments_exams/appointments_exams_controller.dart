import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/consulta/consulta_model.dart';
import '../../../../../../model/exame/exame_model.dart';
import '../../../../../../repositories/consulta/consulta_repository.dart';
import '../../../../../../repositories/exame/exame_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';

part 'appointments_exams_controller.g.dart';

class AppointmentsExamsController = AppointmentsExamsControllerBase
    with _$AppointmentsExamsController;

/// Controlador de CONSULTAS + EXAMES (Home), com a API como fonte de verdade.
///
/// A gestação ativa é resolvida de [PerfilRepository.getGestacaoAtual]; sem
/// gestação ativa a tela mostra aviso amigável (nunca 404/JSON/PREGNANCY_NOT_FOUND).
/// As listas vêm de [ConsultaRepository] / [ExameRepository] (1—N da gestação).
abstract class AppointmentsExamsControllerBase with Store {
  final PerfilRepository perfilRepository;
  final ConsultaRepository consultaRepository;
  final ExameRepository exameRepository;

  AppointmentsExamsControllerBase(
    this.perfilRepository,
    this.consultaRepository,
    this.exameRepository,
  );

  @observable
  int index = 0;

  @observable
  bool isLoading = false;

  /// `false` quando não há gestação ativa — a tela mostra aviso amigável.
  @observable
  bool hasGestacao = false;

  @observable
  var appointments = ObservableList<ConsultaModel>();

  @observable
  var exams = ObservableList<ExameModel>();

  /// UUID real da gestação ativa (resolvido da API). Nunca um id SQLite/0/1.
  String? _gestacaoId;

  /// Protege contra submit/delete duplo (double-tap) — uma mutação por vez.
  bool _busy = false;

  @action
  void setIndex(int value) {
    index = value;
  }

  @action
  Future<void> initialize() async {
    isLoading = true;
    try {
      await _resolveGestacao();
      final gid = _gestacaoId;
      if (gid == null) {
        hasGestacao = false;
        appointments.clear();
        exams.clear();
        return;
      }
      hasGestacao = true;
      await Future.wait([_getAppointments(), _getExams()]);
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> _resolveGestacao() async {
    final result = await perfilRepository.getGestacaoAtual();
    switch (result) {
      case Success():
        _gestacaoId = result.success?.id;
      case Error():
        _gestacaoId = null;
    }
  }

  @action
  Future<void> _getAppointments() async {
    final result = await consultaRepository.listConsultas(_gestacaoId!);
    switch (result) {
      case Success():
        appointments.clear();
        appointments.addAll(result.success);
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  @action
  Future<void> _getExams() async {
    final result = await exameRepository.listExames(_gestacaoId!);
    switch (result) {
      case Success():
        exams.clear();
        exams.addAll(result.success);
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  @action
  Future<void> saveAppointment(ConsultaModel consulta) async {
    if (_busy) return;
    final gid = _gestacaoId;
    if (gid == null) {
      Messages.showInfo('Cadastre sua gestação para adicionar consultas.');
      return;
    }
    _busy = true;
    try {
      final result = await consultaRepository.createConsulta(gid, consulta);
      switch (result) {
        case Success():
          await _getAppointments();
          Messages.showSuccess('Consulta salva');
        case Error(error: final failure):
          Messages.showError(failure.message);
      }
    } finally {
      _busy = false;
    }
  }

  @action
  Future<void> saveExam(ExameModel exame) async {
    if (_busy) return;
    final gid = _gestacaoId;
    if (gid == null) {
      Messages.showInfo('Cadastre sua gestação para adicionar exames.');
      return;
    }
    _busy = true;
    try {
      final result = await exameRepository.createExame(gid, exame);
      switch (result) {
        case Success():
          await _getExams();
          Messages.showSuccess('Exame salvo');
        case Error(error: final failure):
          Messages.showError(failure.message);
      }
    } finally {
      _busy = false;
    }
  }

  @action
  Future<void> deleteAppointment(String id) async {
    if (_busy) return;
    final gid = _gestacaoId;
    if (gid == null) return;
    _busy = true;
    try {
      final result = await consultaRepository.deleteConsulta(gid, id);
      switch (result) {
        case Success():
          await _getAppointments();
          Messages.showSuccess('Consulta deletada');
        case Error(error: final failure):
          Messages.showError(failure.message);
      }
    } finally {
      _busy = false;
    }
  }

  @action
  Future<void> deleteExam(String id) async {
    if (_busy) return;
    final gid = _gestacaoId;
    if (gid == null) return;
    _busy = true;
    try {
      final result = await exameRepository.deleteExame(gid, id);
      switch (result) {
        case Success():
          await _getExams();
          Messages.showSuccess('Exame deletado');
        case Error(error: final failure):
          Messages.showError(failure.message);
      }
    } finally {
      _busy = false;
    }
  }
}
