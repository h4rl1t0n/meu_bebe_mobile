import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../../core/helpers/civil_date.dart';
import '../../../../model/gestacao/gestacao_model.dart';
import '../../../../model/gestante/gestante_model.dart';
import '../../../../model/historico_obstetrico/historico_obstetrico_model.dart';
import '../../../../repositories/consulta/consulta_repository.dart';
import '../../../../repositories/exame/exame_repository.dart';
import '../../../../repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import '../../../../repositories/perfil/perfil_repository.dart';

part 'gestation_controller.g.dart';

class GestationController = GestationControllerBase with _$GestationController;

/// Controlador (somente leitura) da ABA GESTAÇÃO.
///
/// Fonte de verdade dos domínios migrados:
///  - gestante (nome, data de nascimento)  → [PerfilRepository.getGestante]
///  - gestação atual (DUM e pré-natal)     → [PerfilRepository.getGestacaoAtual]
///  - histórico obstétrico                 → [HistoricoObstetricoRepository.getHistorico]
///  - consultas                            → [ConsultaRepository.listConsultas]
///  - exames                               → [ExameRepository.listExames]
///
/// Consultas/exames pertencem à GESTAÇÃO: só são listados quando há gestação
/// ativa (UUID real vindo da API — nunca id SQLite/0/1).
abstract class GestationControllerBase with Store {
  final PerfilRepository perfilRepository;
  final HistoricoObstetricoRepository historicoObstetricoRepository;
  final ConsultaRepository consultaRepository;
  final ExameRepository exameRepository;

  GestationControllerBase(
    this.perfilRepository,
    this.historicoObstetricoRepository,
    this.consultaRepository,
    this.exameRepository,
  );

  @observable
  GestanteModel? gestante;

  @observable
  GestacaoModel? gestacao;

  @observable
  HistoricoObstetricoModel? historico;

  @observable
  ObservableList<String> appointments = ObservableList<String>();

  @observable
  ObservableList<String> exams = ObservableList<String>();

  @observable
  bool isLoading = false;

  @action
  Future<void> initialize() async {
    isLoading = true;
    try {
      await Future.wait([
        _getGestante(),
        _getGestacao(),
        _getHistorico(),
      ]);
      final gestacaoId = gestacao?.id;
      if (gestacaoId != null) {
        await Future.wait([
          _getAppointments(gestacaoId),
          _getExams(gestacaoId),
        ]);
      } else {
        appointments.clear();
        exams.clear();
      }
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> _getGestante() async {
    final result = await perfilRepository.getGestante();
    switch (result) {
      case Success():
        gestante = result.success;
      case Error():
        gestante = null;
    }
  }

  @action
  Future<void> _getGestacao() async {
    final result = await perfilRepository.getGestacaoAtual();
    switch (result) {
      case Success():
        gestacao = result.success;
      case Error():
        gestacao = null;
    }
  }

  @action
  Future<void> _getHistorico() async {
    final result = await historicoObstetricoRepository.getHistorico();
    switch (result) {
      case Success():
        historico = result.success;
      case Error():
        historico = null;
    }
  }

  @action
  Future<void> _getAppointments(String gestacaoId) async {
    final result = await consultaRepository.listConsultas(gestacaoId);
    switch (result) {
      case Success():
        appointments.clear();
        appointments.addAll(
          result.success.map(
            (a) => '${a.titulo} - ${civilDateIsoToDisplay(a.dataConsulta)}',
          ),
        );
      case Error():
        break;
    }
  }

  @action
  Future<void> _getExams(String gestacaoId) async {
    final result = await exameRepository.listExames(gestacaoId);
    switch (result) {
      case Success():
        exams.clear();
        exams.addAll(
          result.success.map(
            (e) => '${e.titulo} - ${civilDateIsoToDisplay(e.dataExame)}',
          ),
        );
      case Error():
        break;
    }
  }

  /// Linhas do "Histórico de gestações" exibido na aba. `null` (não informado)
  /// difere de `0` (zero ocorrências) — nunca converte `null` em zero.
  @computed
  List<String> get historyItems {
    final h = historico;
    return [
      'Gravidezes anteriores: ${_count(h?.pregnancyNumber)}',
      'Partos anteriores: ${_count(h?.givenBirthNumber)}',
      'Abortos: ${_count(h?.abortionsNumber)}',
    ];
  }

  String _count(int? value) => value == null ? 'Sem dados' : '$value';
}
