import 'dart:developer';

import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../model/exame/exame_model.dart';
import '../../../../../../model/gestacao/gestacao_model.dart';
import '../../../../../../model/gestante/gestante_model.dart';
import '../../../../../../model/historico_obstetrico/historico_obstetrico_model.dart';
import '../../../../../../model/plano_parto/plano_parto_model.dart';
import '../../../../../../repositories/exame/exame_repository.dart';
import '../../../../../../repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';
import '../../../../../../repositories/plano_parto/plano_parto_repository.dart';

part 'childbirth_resume_controller.g.dart';

class ChildbirthResumeController = ChildbirthResumeControllerBase
    with _$ChildbirthResumeController;

/// Controlador do resumo do Plano de Parto — API como fonte de verdade.
///
/// Domínios lidos da API:
///  - gestante      → [PerfilRepository.getGestante]
///  - gestação      → [PerfilRepository.getGestacaoAtual] (DUM + pré-natal)
///  - histórico     → [HistoricoObstetricoRepository.getHistorico]
///  - plano de parto → [PlanoPartoRepository.getPlanoParto] (singleton, 28 campos)
///
/// A primeira ultrassonografia vem de EXAMES
/// ([ExameModel.firstUltrasoundDate]) — não há campo duplicado em GESTAÇÃO.
abstract class ChildbirthResumeControllerBase with Store {
  final PerfilRepository perfilRepository;
  final HistoricoObstetricoRepository historicoObstetricoRepository;
  final ExameRepository exameRepository;
  final PlanoPartoRepository planoPartoRepository;

  ChildbirthResumeControllerBase({
    required this.perfilRepository,
    required this.historicoObstetricoRepository,
    required this.exameRepository,
    required this.planoPartoRepository,
  });

  @observable
  GestanteModel? gestante;

  @observable
  GestacaoModel? gestacao;

  @observable
  HistoricoObstetricoModel? historico;

  /// Primeira ultrassonografia (ISO `AAAA-MM-DD`) derivada de EXAMES, ou `null`.
  @observable
  String? firstUltrasound;

  /// Plano de parto consolidado (28 campos), ou `null` se ainda não existe.
  @observable
  PlanoPartoModel? plano;

  @observable
  bool isLoading = false;

  @action
  Future<void> initialize() async {
    isLoading = true;
    try {
      await Future.wait([
        getGestante(),
        getGestacao(),
        getHistorico(),
      ]);
      // Dependem do `gestacao.id` resolvido em getGestacao() — não podem rodar
      // em paralelo no Future.wait acima.
      await Future.wait([getFirstUltrasound(), getPlanoParto()]);
    } catch (e) {
      // Um componente que lança não pode deixar o loading eterno nem quebrar
      // os demais: os getters já tratam Error/Result e expõem null em falha.
      log('Erro ao carregar o resumo do plano de parto: $e');
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> getGestante() async {
    final result = await perfilRepository.getGestante();
    switch (result) {
      case Error():
        log('Error getting gestante');
        gestante = null;
      case Success():
        gestante = result.success;
    }
  }

  @action
  Future<void> getGestacao() async {
    final result = await perfilRepository.getGestacaoAtual();
    switch (result) {
      case Error():
        log('Error getting current gestation');
        gestacao = null;
      case Success():
        gestacao = result.success;
    }
  }

  @action
  Future<void> getHistorico() async {
    final result = await historicoObstetricoRepository.getHistorico();
    switch (result) {
      case Error():
        log('Error getting history');
        historico = null;
      case Success():
        historico = result.success;
    }
  }

  @action
  Future<void> getFirstUltrasound() async {
    final gestacaoId = gestacao?.id;
    if (gestacaoId == null) {
      firstUltrasound = null;
      return;
    }
    final result = await exameRepository.listExames(gestacaoId);
    switch (result) {
      case Error():
        firstUltrasound = null;
      case Success():
        firstUltrasound = ExameModel.firstUltrasoundDate(result.success);
    }
  }

  @action
  Future<void> getPlanoParto() async {
    final gestacaoId = gestacao?.id;
    if (gestacaoId == null) {
      plano = null;
      return;
    }
    final result = await planoPartoRepository.getPlanoParto(gestacaoId);
    switch (result) {
      case Error():
        log('Error getting plano de parto');
        plano = null;
      case Success():
        plano = result.success;
    }
  }
}
