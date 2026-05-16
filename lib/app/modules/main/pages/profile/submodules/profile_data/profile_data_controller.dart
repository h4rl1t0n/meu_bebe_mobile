import 'dart:developer';

import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../core/helpers/messages.dart';
import '../../../../../../model/pregnant_data.dart';
import '../../../../../../model/user_data.dart';
import '../../../../../../repositories/gestation/gestation_repository.dart';
import '../../../../../../repositories/profile/profile_repository.dart';

part 'profile_data_controller.g.dart';

class ProfileDataController = ProfileDataControllerBase with _$ProfileDataController;

abstract class ProfileDataControllerBase with Store {
  final GestationRepository gestationRepository;
  final ProfileRepository profileRepository;

  ProfileDataControllerBase(this.gestationRepository, this.profileRepository);

  @observable
  PregnantData? pregnant;

  @observable
  UserData? user;

  @observable
  bool loading = true;

  @observable
  bool formEnabled = true;

  @action
  void setFormEnabled(bool enabled) {
    formEnabled = enabled;
  }

  @action
  Future<void> initialize() async {
    try {
      loading = true;

      await Future.wait([getGestationElements(), getUserElements()]);
    } finally {
      loading = false;
    }
  }

  @action
  Future<void> getGestationElements() async {
    final result = await gestationRepository.getPregnant();

    switch (result) {
      case Success():
        pregnant = result.success;

      case Error():
        log('Falha ao buscar dados de gestação');
    }
  }

  @action
  Future<void> getUserElements() async {
    final result = await profileRepository.getUser();

    switch (result) {
      case Success():
        user = result.success;

      case Error():
        log('Falha ao buscar usuário');
    }
  }

  Future<bool> saveProfile(PregnantData pregnant, UserData user) async {
    final results = await Future.wait([_saveGestation(pregnant), _saveUser(user)]);

    final gestationSuccess = results[0];
    final userSuccess = results[1];

    if (gestationSuccess && userSuccess) {
      Messages.showSuccess('Dados salvos');
      Modular.to.pop();
      return true;
    }

    Messages.showError('Falha ao salvar os dados');
    return false;
  }

  Future<bool> _saveGestation(PregnantData pregnant) async {
    final result = await gestationRepository.updatePregnant(pregnant: pregnant);

    switch (result) {
      case Success():
        log('${result.success.name} salvo');
        return true;

      case Error():
        log(result.error.message);
        return false;
    }
  }

  Future<bool> _saveUser(UserData user) async {
    final result = await profileRepository.updateUser(user: user);

    switch (result) {
      case Success():
        log(result.success.name);
        return true;

      case Error():
        log(result.error.message);
        return false;
    }
  }
}
