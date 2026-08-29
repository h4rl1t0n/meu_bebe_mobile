import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/medicamento/medicamento_model.dart';
import '../../../../../../repositories/medicamento/medicamento_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';

part 'medication_controller.g.dart';

class MedicationController = MedicationControllerBase with _$MedicationController;

/// Controlador de MEDICAMENTOS (Home), com a API como fonte de verdade.
///
/// A gestação ativa é resolvida de [PerfilRepository.getGestacaoAtual]; sem
/// gestação ativa a tela mostra aviso amigável. A lista vem de
/// [MedicamentoRepository] (1—N da gestação). Ordenação canônica (nome) é do
/// backend — o Flutter não reordena.
abstract class MedicationControllerBase with Store {
  final PerfilRepository perfilRepository;
  final MedicamentoRepository medicamentoRepository;

  MedicationControllerBase(this.perfilRepository, this.medicamentoRepository);

  @observable
  bool isLoading = false;

  /// `false` quando não há gestação ativa — a tela mostra aviso amigável.
  @observable
  bool hasGestacao = false;

  @observable
  var medications = ObservableList<MedicamentoModel>();

  /// UUID real da gestação ativa (resolvido da API). Nunca um id SQLite/0/1.
  String? _gestacaoId;

  /// Protege contra submit/delete duplo (double-tap) — uma mutação por vez.
  bool _busy = false;

  @action
  Future<void> initialize() async {
    isLoading = true;
    try {
      await _resolveGestacao();
      final gid = _gestacaoId;
      if (gid == null) {
        hasGestacao = false;
        medications.clear();
        return;
      }
      hasGestacao = true;
      await _getMedications();
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
  Future<void> _getMedications() async {
    final result = await medicamentoRepository.listMedicamentos(_gestacaoId!);
    switch (result) {
      case Success():
        medications.clear();
        medications.addAll(result.success);
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  @action
  Future<void> saveMedication(MedicamentoModel medicamento) async {
    if (_busy) return;
    final gid = _gestacaoId;
    if (gid == null) {
      Messages.showInfo('Cadastre sua gestação para adicionar medicamentos.');
      return;
    }
    _busy = true;
    try {
      final result = await medicamentoRepository.createMedicamento(
        gid,
        medicamento,
      );
      switch (result) {
        case Success():
          await _getMedications();
          Messages.showSuccess('Medicamento salvo');
        case Error(error: final failure):
          Messages.showError(failure.message);
      }
    } finally {
      _busy = false;
    }
  }

  @action
  Future<void> deleteMedication(String id) async {
    if (_busy) return;
    final gid = _gestacaoId;
    if (gid == null) return;
    _busy = true;
    try {
      final result = await medicamentoRepository.deleteMedicamento(gid, id);
      switch (result) {
        case Success():
          await _getMedications();
          Messages.showSuccess('Medicamento deletado');
        case Error(error: final failure):
          Messages.showError(failure.message);
      }
    } finally {
      _busy = false;
    }
  }
}
