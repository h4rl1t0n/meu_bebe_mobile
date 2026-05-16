// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/previous_pregnancy.dart';
import '../../../../../../repositories/history/history_repository.dart';

part 'history_controller.g.dart';

class HistoryController = HistoryControllerBase with _$HistoryController;

abstract class HistoryControllerBase with Store {
  final HistoryRepository repository;

  @observable
  bool saved = false;

  @observable
  PreviousPregnancy? model;

  HistoryControllerBase(this.repository);

  @action
  Future<void> initialize() async {
    final result = await repository.getHistory();

    switch (result) {
      case Error():
        Messages.showError('Erro ao pegar dados de gravidez anteriores');
      case Success():
        model = result.success;
    }

    model ??= const PreviousPregnancy(id: 0);
  }

  @action
  Future<void> saveHistory(PreviousPregnancy history) async {
    final result = await repository.updateHistory(history: history);

    switch (result) {
      case Error():
        Messages.showError('Erro ao salvar os dados');
      case Success():
        Messages.showSuccess('Dados salvos com sucesso');
        model = result.success;
        saved = true;
    }
  }
}
