import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/birth.dart';
import '../../../../../../repositories/birth/birth_repository.dart';

part 'birth_controller.g.dart';

class BirthController = BirthControllerBase with _$BirthController;

abstract class BirthControllerBase with Store {
  final BirthRepository repository;

  @observable
  bool saved = false;

  @observable
  Birth? birth;

  BirthControllerBase(this.repository);

  @action
  Future<void> initialize() async {
    final result = await repository.getBirth();

    switch (result) {
      case Error():
        Messages.showError('Erro ao pegar dados do nascimento');
      case Success():
        birth = result.success;
    }

    birth ??= const Birth(
      id: 0,
      whoCut: WhoCutUmbilicalCord.professional,
      collectStemCells: false,
      skinBabyContact: SkinBabyContact.yes,
      breastfeedFirstHour: BreastfeedFirstHour.yes,
      breastfeedRestrictions: false,
      firstBath: FirstBath.professional,
    );
  }

  @action
  Future<void> saveBirth(Birth birth) async {
    final result = await repository.updateBirth(birth: birth);

    switch (result) {
      case Error():
        Messages.showError('Erro ao salvar dados');
      case Success():
        Messages.showSuccess('Dados salvos com sucesso');
        this.birth = result.success;
        saved = true;
    }
  }
}
