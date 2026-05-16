import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/birth_moment.dart';
import '../../../../../../repositories/birth_moment/birth_moment_repository.dart';

part 'birth_moment_controller.g.dart';

class BirthMomentController = BirthMomentControllerBase with _$BirthMomentController;

abstract class BirthMomentControllerBase with Store {
  final BirthMomentRepository repository;

  @observable
  bool saved = false;

  @observable
  BirthMoment? birthMoment;

  BirthMomentControllerBase(this.repository);

  @action
  Future<void> initialize() async {
    final result = await repository.getBirthMoment();

    switch (result) {
      case Error():
        Messages.showError('Erro ao pegar dados do momento do parto');
      case Success():
        birthMoment = result.success;
    }

    birthMoment ??= const BirthMoment(
      id: 0,
      birthWay: BirthWay.vaginal,
      anesthesia: Anesthesia.yes,
      vaginalCut: VaginalCut.yes,
    );
  }

  @action
  Future<void> saveBirthMoment(BirthMoment birthMoment) async {
    final result = await repository.updateBirthMoment(birthMoment: birthMoment);

    switch (result) {
      case Error():
        Messages.showError('Erro ao salvar dados');
      case Success():
        Messages.showSuccess('Dados salvos com sucesso');
        this.birthMoment = result.success;
        saved = true;
    }
  }
}
