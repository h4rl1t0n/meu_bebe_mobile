import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/pain_relief.dart';
import '../../../../../../repositories/pain_relief/pain_relief_repository.dart';

part 'pain_relief_controller.g.dart';

class PainReliefController = PainReliefControllerBase with _$PainReliefController;

abstract class PainReliefControllerBase with Store {
  final PainReliefRepository repository;

  @observable
  bool saved = false;

  @observable
  PainRelief? painRelief;

  PainReliefControllerBase(this.repository);

  @action
  Future<void> initialize() async {
    final result = await repository.getPainRelief();

    switch (result) {
      case Error():
        Messages.showError('Erro ao pegar dados de alívio da dor');
      case Success():
        painRelief = result.success;
    }

    painRelief ??= const PainRelief(
      id: 0,
      painRelief: NeedPainRelief.no,
      massage: false,
      ballExercises: false,
      breathRelaxExercises: false,
      showerBath: false,
      bathtubBath: false,
      acupuncture: false,
      acupressure: false,
      otherMethod: false,
    );
  }

  @action
  Future<void> savePainRelief(PainRelief painRelief) async {
    final result = await repository.updatePainRelief(painRelief: painRelief);

    switch (result) {
      case Error():
        Messages.showError('Erro ao salvar dados');
      case Success():
        Messages.showSuccess('Dados salvos com sucesso');
        this.painRelief = result.success;
        saved = true;
    }
  }
}
