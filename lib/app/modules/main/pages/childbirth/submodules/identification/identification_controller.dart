import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/pregnant_data.dart';
import '../../../../../../repositories/gestation/gestation_repository.dart';

part 'identification_controller.g.dart';

class IdentificationController = IdentificationControllerBase with _$IdentificationController;

abstract class IdentificationControllerBase with Store {
  final GestationRepository repository;

  IdentificationControllerBase(this.repository);

  @observable
  bool _saved = false;

  @computed
  bool get saved => _saved;

  @observable
  PregnantData? _model;

  @computed
  PregnantData? get model => _model;

  @action
  Future<void> initialize() async {
    final result = await repository.getPregnant();

    switch (result) {
      case Error():
        Messages.showError('Erro ao pegar dados da gestante');
      case Success():
        _model = result.success;
    }

    _model ??= PregnantData(
      id: 0,
      name: '',
      socialName: '',
      birthDate: '',
      cpf: '',
      nationalHealthCard: '',
      prenatalPlace: '',
      professionalName: '',
      prenatalPlaceContact: '',
    );
  }

  @action
  Future<void> saveIdentification(PregnantData model) async {
    final result = await repository.updatePregnant(pregnant: model);

    switch (result) {
      case Error():
        Messages.showError('Erro ao salvar os dados');
      case Success():
        Messages.showSuccess('Dados salvos com sucesso');
        _model = result.success;
        _saved = true;
    }
  }
}
