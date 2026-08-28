import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/historico_obstetrico/historico_obstetrico_model.dart';
import '../../../../../../repositories/historico_obstetrico/historico_obstetrico_repository.dart';

part 'history_controller.g.dart';

class HistoryController = HistoryControllerBase with _$HistoryController;

abstract class HistoryControllerBase with Store {
  final HistoricoObstetricoRepository repository;

  @observable
  bool loading = true;

  @observable
  HistoricoObstetricoModel? model;

  HistoryControllerBase(this.repository);

  @action
  Future<void> initialize() async {
    loading = true;
    final result = await repository.getHistorico();

    switch (result) {
      case Success(success: final historico):
        model = historico;
      case Error():
        model = null;
    }

    loading = false;
  }

  /// Salva (PUT upsert) o histórico obstétrico. Retorna `true` em sucesso.
  @action
  Future<bool> save(HistoricoObstetricoModel data) async {
    if (loading) return false;
    loading = true;

    final result = await repository.saveHistorico(data);

    loading = false;

    switch (result) {
      case Success(success: final historico):
        model = historico;
        Messages.showSuccess('Dados salvos com sucesso');
        return true;
      case Error(error: final failure):
        Messages.showError(failure.message);
        return false;
    }
  }
}
