import 'dart:developer';

import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../../../model/birth.dart';
import '../../../../../../model/birth_moment.dart';
import '../../../../../../model/expectation.dart';
import '../../../../../../model/exame/exame_model.dart';
import '../../../../../../model/gestacao/gestacao_model.dart';
import '../../../../../../model/gestante/gestante_model.dart';
import '../../../../../../model/historico_obstetrico/historico_obstetrico_model.dart';
import '../../../../../../model/observations.dart';
import '../../../../../../model/pain_relief.dart';
import '../../../../../../repositories/birth/birth_repository.dart';
import '../../../../../../repositories/birth_moment/birth_moment_repository.dart';
import '../../../../../../repositories/exame/exame_repository.dart';
import '../../../../../../repositories/expectations/expectations_repository.dart';
import '../../../../../../repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import '../../../../../../repositories/observations/observations_repository.dart';
import '../../../../../../repositories/pain_relief/pain_relief_repository.dart';
import '../../../../../../repositories/perfil/perfil_repository.dart';

part 'childbirth_resume_controller.g.dart';

class ChildbirthResumeController = ChildbirthResumeControllerBase
    with _$ChildbirthResumeController;

/// Controlador do resumo do Plano de Parto.
///
/// Domínios migrados (9A/9B) lidos da API:
///  - gestante      → [PerfilRepository.getGestante]
///  - gestação      → [PerfilRepository.getGestacaoAtual] (DUM + pré-natal)
///  - histórico     → [HistoricoObstetricoRepository.getHistorico]
///
/// Permanecem locais (SQLite) somente os domínios do Plano de Parto ainda NÃO
/// integrados (expectativas, momento do parto, nascimento, alívio de dor,
/// observações). A primeira ultrassonografia vem de EXAMES
/// ([ExameModel.firstUltrasoundDate]) — não há campo duplicado em GESTAÇÃO.
abstract class ChildbirthResumeControllerBase with Store {
  final PerfilRepository perfilRepository;
  final HistoricoObstetricoRepository historicoObstetricoRepository;
  final ExameRepository exameRepository;
  final ExpectationsRepository expectationsRepository;
  final BirthMomentRepository birthMomentRepository;
  final BirthRepository birthRepository;
  final PainReliefRepository painReliefRepository;
  final ObservationsRepository observationsRepository;

  ChildbirthResumeControllerBase({
    required this.perfilRepository,
    required this.historicoObstetricoRepository,
    required this.exameRepository,
    required this.expectationsRepository,
    required this.birthMomentRepository,
    required this.birthRepository,
    required this.painReliefRepository,
    required this.observationsRepository,
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

  @observable
  Expectation? expectationsData;

  @observable
  BirthMoment? birthMomentData;

  @observable
  Birth? birthData;

  @observable
  PainRelief? painReliefData;

  @observable
  Observations? observationsData;

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
        getExpectations(),
        getBirthMoment(),
        getBirth(),
        getPainRelief(),
        getObservations(),
      ]);
      // Depende do `gestacao.id` resolvido em getGestacao() — não pode rodar em
      // paralelo no Future.wait acima.
      await getFirstUltrasound();
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
  Future<void> getExpectations() async {
    final result = await expectationsRepository.getExpectations();
    switch (result) {
      case Error():
        log('Error getting expectations');
      case Success():
        expectationsData = result.success;
    }
  }

  @action
  Future<void> getBirthMoment() async {
    final result = await birthMomentRepository.getBirthMoment();
    switch (result) {
      case Error():
        log('Error getting birth moment');
      case Success():
        birthMomentData = result.success;
    }
  }

  @action
  Future<void> getBirth() async {
    final result = await birthRepository.getBirth();
    switch (result) {
      case Error():
        log('Error getting birth data');
      case Success():
        birthData = result.success;
    }
  }

  @action
  Future<void> getPainRelief() async {
    final result = await painReliefRepository.getPainRelief();
    switch (result) {
      case Error():
        log('Error getting pain relief');
      case Success():
        painReliefData = result.success;
    }
  }

  @action
  Future<void> getObservations() async {
    final result = await observationsRepository.getObservations();
    switch (result) {
      case Error():
        log('Error getting observations');
      case Success():
        observationsData = result.success;
    }
  }
}
