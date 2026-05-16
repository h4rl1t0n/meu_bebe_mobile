import 'dart:developer';

import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/vaccine_data.dart';
import '../../../../../../repositories/vaccines/vaccines_repository.dart';

part 'vaccines_controller.g.dart';

class VaccinesController = VaccinesControllerBase with _$VaccinesController;

abstract class VaccinesControllerBase with Store {
  final VaccinesRepository repository;

  @observable
  var vaccines = ObservableList<VaccineData>();

  @observable
  bool updated = false;

  @action
  void resetUpdated() => updated = false;

  Future<void> initialize() async {
    await getVaccines();
  }

  VaccinesControllerBase(this.repository);

  @action
  Future<void> getVaccines() async {
    final result = await repository.getVaccines();

    switch (result) {
      case Success():
        if (result.success.isEmpty) return _setVaccines();

        vaccines.clear();
        vaccines.addAll(result.success);
        _sortVaccines();
        return;
      case Error():
        Messages.showError(result.error.message);
    }
  }

  Future<void> _saveVaccine(VaccineData vaccine) async {
    final result = await repository.saveVaccine(vaccine: vaccine);

    switch (result) {
      case Success():
        log('Vacina ${result.success.name} salva');
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  @action
  Future<void> _setVaccines() async {
    await _saveVaccine(const VaccineData(id: 0, name: 'HB_1', used: false));
    await _saveVaccine(const VaccineData(id: 1, name: 'HB_2', used: false));
    await _saveVaccine(const VaccineData(id: 2, name: 'HB_3', used: false));
    await _saveVaccine(const VaccineData(id: 3, name: 'dT_1', used: false));
    await _saveVaccine(const VaccineData(id: 4, name: 'dT_2', used: false));
    await _saveVaccine(const VaccineData(id: 5, name: 'dT_3', used: false));
    await _saveVaccine(const VaccineData(id: 6, name: 'dTpa', used: false));
    await getVaccines();
    updated = true;
  }

  @action
  Future<void> updateVaccine(VaccineData vaccine) async {
    final result = await repository.saveVaccine(vaccine: vaccine);

    switch (result) {
      case Success():
        final updatedVaccine = result.success;
        final index = vaccines.indexWhere((v) => v.id == updatedVaccine.id);
        if (index != -1) {
          vaccines[index] = updatedVaccine;
        }
        _sortVaccines();
        updated = true;
      case Error(error: final failure):
        Messages.showError(failure.message);
    }
  }

  @action
  void _sortVaccines() {
    vaccines.sort((a, b) => a.id.compareTo(b.id));
  }

}
