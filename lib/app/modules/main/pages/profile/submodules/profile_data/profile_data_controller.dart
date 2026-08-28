import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/gestante/gestante_model.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';

part 'profile_data_controller.g.dart';

class ProfileDataController = ProfileDataControllerBase with _$ProfileDataController;

abstract class ProfileDataControllerBase with Store {
  final PerfilRepository perfilRepository;

  ProfileDataControllerBase(this.perfilRepository);

  @observable
  GestanteModel? gestante;

  @observable
  String? email;

  @observable
  bool loading = true;

  @observable
  bool formEnabled = true;

  @action
  void setFormEnabled(bool enabled) => formEnabled = enabled;

  @action
  Future<void> initialize() async {
    loading = true;

    final gestanteResult = await perfilRepository.getGestante();
    switch (gestanteResult) {
      case Success(success: final value):
        gestante = value;
      case Error():
        gestante = null;
    }

    final userResult = await perfilRepository.getUser();
    switch (userResult) {
      case Success(success: final value):
        email = value?.email;
      case Error():
        email = null;
    }

    loading = false;
  }

  /// Cria (se ainda não existir) ou atualiza o perfil de gestante no backend.
  @action
  Future<bool> saveProfile(GestanteModel data) async {
    if (loading) return false;
    loading = true;
    final result = gestante == null
        ? await perfilRepository.createGestante(data)
        : await perfilRepository.updateGestante(data);
    loading = false;

    switch (result) {
      case Success(success: final saved):
        gestante = saved;
        Messages.showSuccess('Dados salvos');
        return true;
      case Error(error: final failure):
        Messages.showError(failure.message);
        return false;
    }
  }
}
