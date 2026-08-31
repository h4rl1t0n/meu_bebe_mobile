import 'package:mobx/mobx.dart';

part 'configuracoes_controller.g.dart';

class ConfiguracoesController = ConfiguracoesControllerBase
    with _$ConfiguracoesController;

/// Estado local das preferências de notificação/lembretes da tela de
/// Configurações. Estado transitório de UI (não persistido), mantido em MobX
/// para eliminar o `setState`.
abstract class ConfiguracoesControllerBase with Store {
  @observable
  bool notificacoesAtivas = true;

  @observable
  bool lembretesConsulta = true;

  @observable
  bool lembretesVacina = true;

  @observable
  bool lembretesMedicacao = true;

  @action
  void setNotificacoesAtivas(bool value) => notificacoesAtivas = value;

  @action
  void setLembretesConsulta(bool value) => lembretesConsulta = value;

  @action
  void setLembretesVacina(bool value) => lembretesVacina = value;

  @action
  void setLembretesMedicacao(bool value) => lembretesMedicacao = value;
}
