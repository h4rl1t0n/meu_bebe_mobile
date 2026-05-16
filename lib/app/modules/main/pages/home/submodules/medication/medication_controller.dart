import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/medication.dart';
import '../../../../../../repositories/medication/medication_repository.dart';

part 'medication_controller.g.dart';

class MedicationController = MedicationControllerBase with _$MedicationController;

abstract class MedicationControllerBase with Store {
  final MedicationRepository repository;

  @observable
  var medications = ObservableList<Medication>();

  @observable
  bool updated = false;

  @action
  void resetUpdated() => updated = false;

  Future<void> initialize() async {
    await _getMedications();
  }

  MedicationControllerBase(this.repository);

  @action
  Future<void> _getMedications() async {
    final result = await repository.getMedications();

    switch (result) {
      case Success():
        medications.clear();
        medications.addAll(result.success);
        _sortMedications();
      case Error():
        Messages.showError(result.error.message);
    }
  }

  @action
  Future<void> saveMedication(Medication medication) async {
    final result = await repository.saveMedication(medication: medication);

    switch (result) {
      case Success():
        medications.add(result.success);
        _sortMedications();
        updated = true;
        Messages.showSuccess('Medicamento salvo');
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  @action
  Future<void> deleteMedication(int id) async {
    final result = await repository.deleteMedication(id: id);

    switch (result) {
      case Success():
        if (result.success) {
          medications.removeWhere((medication) => medication.id == id);
          _sortMedications();
          updated = true;
          Messages.showSuccess('Medicamento deletado');
        }
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  @action
  void _sortMedications() {
    medications.sort((a, b) {
      return a.name.compareTo(b.name);
    });
  }
}
