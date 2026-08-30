import 'package:mobx/mobx.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../enum/page_status.dart';
import '../../../repositories/avaliacao_dss/avaliacao_dss_repository.dart';
import '../../../repositories/perfil/perfil_repository.dart';
import '../../../repositories/risk_estimate/risk_estimate_repository.dart';
import '../catalog/alimentacao_options.dart';
import '../catalog/educacao_options.dart';
import '../catalog/habitacao_options.dart';
import '../catalog/saneamento_options.dart';
import '../catalog/saude_options.dart';
import '../catalog/trabalho_options.dart';
import '../models/formulario_data.dart';
import '../models/risk_estimate/risk_estimate_response_model.dart';
import '../submodules/alimentacao/alimentacao_controller.dart';
import '../submodules/educacao/educacao_controller.dart';
import '../submodules/habitacao/habitacao_controller.dart';
import '../submodules/saneamento/saneamento_controller.dart';
import '../submodules/saude/saude_controller.dart';
import '../submodules/trabalho/trabalho_controller.dart';

part 'formulario_controller.g.dart';

class FormularioController = FormularioControllerBase
    with _$FormularioController;

abstract class FormularioControllerBase with Store {
  final RiskEstimateRepository riskEstimateRepository;
  final AvaliacaoDssRepository avaliacaoDssRepository;
  final PerfilRepository perfilRepository;
  final EducacaoController educacaoCtrl;
  final TrabalhoController trabalhoCtrl;
  final SaneamentoController saneamentoCtrl;
  final SaudeController saudeCtrl;
  final HabitacaoController habitacaoCtrl;
  final AlimentacaoController alimentacaoCtrl;

  FormularioControllerBase({
    required this.riskEstimateRepository,
    required this.avaliacaoDssRepository,
    required this.perfilRepository,
    required this.educacaoCtrl,
    required this.trabalhoCtrl,
    required this.saneamentoCtrl,
    required this.saudeCtrl,
    required this.habitacaoCtrl,
    required this.alimentacaoCtrl,
  });

  @observable
  int currentStep = 0;

  @observable
  PageStatus status = PageStatus.initial;

  @observable
  RiskEstimateResponseModel? riskEstimate;

  @observable
  String? error;

  // Estado da persistência operacional (FASE 9F). São campos PLAIN (não
  // `@observable`): são lidos imperativamente após `await enviarFormulario()`
  // (callback da página e testes), não via Observer/reaction. Mantidos
  // SEPARADOS do estado da estimativa (`status`/`error`/`riskEstimate`) para
  // preservar a independência das duas responsabilidades.
  bool persisted = false;
  String? persistenceError;
  bool noActiveGestacao = false;

  @computed
  bool get loading => status == PageStatus.loading;

  @computed
  bool get isFirstStep => currentStep == 0;

  @computed
  bool get isLastStep => currentStep == 5;

  @computed
  FormularioData get consolidatedData => FormularioData(
    educacao: educacaoCtrl.buildEducacaoData(),
    trabalho: trabalhoCtrl.buildTrabalhoData(),
    saneamento: saneamentoCtrl.buildSaneamentoData(),
    saude: saudeCtrl.buildSaudeData(),
    habitacao: habitacaoCtrl.buildHabitacaoData(),
    alimentacao: alimentacaoCtrl.buildAlimentacaoData(),
  );

  @action
  void proximo() {
    if (currentStep < 5 && _isCurrentStepValid()) {
      currentStep++;
    }
  }

  @action
  void voltar() {
    if (currentStep > 0) {
      currentStep--;
    }
  }

  @action
  void goToStep(int step) {
    if (step >= 0 && step <= 5) {
      currentStep = step;
    }
  }

  /// Restaura todo o estado para uma NOVA avaliação (FASE 9G).
  ///
  /// O [FormularioController] e os subcontrollers são SINGLETONS compartilhados
  /// entre navegações para `/form/`. Sem este reset, a reavaliação
  /// pré-preencheria a resposta anterior (proibido — seção 25). Chamado pela
  /// página no `initState`, antes da primeira renderização.
  @action
  void resetForNewAvaliacao() {
    currentStep = 0;
    status = PageStatus.initial;
    riskEstimate = null;
    error = null;
    persisted = false;
    persistenceError = null;
    noActiveGestacao = false;
    educacaoCtrl.reset();
    trabalhoCtrl.reset();
    saneamentoCtrl.reset();
    saudeCtrl.reset();
    habitacaoCtrl.reset();
    alimentacaoCtrl.reset();
  }

  @action
  Future<void> enviarFormulario() async {
    if (loading) return;
    // Guard de inferência (FASE 9G-FIX2): NUNCA envia com campos obrigatórios
    // pendentes. Garante ZERO HTTP antes de qualquer persistência/estimativa,
    // mesmo se chamado diretamente (defesa em profundidade — item 29).
    if (!validateAll()) {
      markAllErrors();
      return;
    }
    status = PageStatus.loading;
    error = null;

    final data = consolidatedData;

    // Responsabilidade A — persistência operacional (append-only), UMA única
    // vez. O guard `!persisted` evita duplicar o POST em retries após sucesso;
    // em caso de falha, `persisted` segue false e a próxima tentativa reenviará.
    if (!persisted) {
      await _persistirAvaliacao(data);
    }

    // Responsabilidade B — estimativa experimental (`/risk-estimate`, stateless).
    // Roda SEMPRE, independente do resultado da persistência (nunca lança).
    final result = await riskEstimateRepository.estimate(data);

    switch (result) {
      case Error(error: final failure):
        status = PageStatus.error;
        error = failure.message;
      case Success(success: final estimate):
        riskEstimate = estimate;
        status = PageStatus.success;
    }
  }

  /// Persiste o snapshot operacional vinculado à gestação atual.
  ///
  /// Sem gestação ativa → NÃO há POST (apenas sinaliza `noActiveGestacao`),
  /// mantendo as respostas intactas e sem auto-criar gestação. A persistência
  /// falha não interrompe a estimativa: apenas registra `persistenceError`.
  Future<void> _persistirAvaliacao(FormularioData data) async {
    final gestacaoResult = await perfilRepository.getGestacaoAtual();

    switch (gestacaoResult) {
      case Error(error: final failure):
        persistenceError = failure.message;
      case Success(success: final gestacao):
        if (gestacao == null) {
          noActiveGestacao = true;
          return;
        }
        final persistResult = await avaliacaoDssRepository.registrar(
          gestacao.id,
          data,
        );
        switch (persistResult) {
          case Error(error: final failure):
            persistenceError = failure.message;
          case Success():
            persisted = true;
        }
    }
  }

  bool isCurrentStepValid() => _isCurrentStepValid();

  bool _isCurrentStepValid() {
    switch (currentStep) {
      case 0:
        return educacaoCtrl.isValid;
      case 1:
        return trabalhoCtrl.isValid;
      case 2:
        return saneamentoCtrl.isValid;
      case 3:
        return saudeCtrl.isValid;
      case 4:
        return habitacaoCtrl.isValid;
      case 5:
        return alimentacaoCtrl.isValid;
      default:
        return false;
    }
  }

  /// Valida TODAS as dimensões (FASE 9G-FIX2, item 13). Usado pelo "Enviar"
  /// antes de mostrar o resumo e, em profundidade, pelo guard de
  /// [enviarFormulario] — garantindo que nenhum HTTP é disparado com campos
  /// obrigatórios pendentes.
  bool validateAll() =>
      educacaoCtrl.isValid &&
      trabalhoCtrl.isValid &&
      saneamentoCtrl.isValid &&
      saudeCtrl.isValid &&
      habitacaoCtrl.isValid &&
      alimentacaoCtrl.isValid;

  /// Índice da primeira dimensão inválida (0..5), ou `null` se todas forem
  /// válidas. Usado para saltar até o primeiro passo com erro (item 14).
  int? get firstInvalidStep {
    if (!educacaoCtrl.isValid) return 0;
    if (!trabalhoCtrl.isValid) return 1;
    if (!saneamentoCtrl.isValid) return 2;
    if (!saudeCtrl.isValid) return 3;
    if (!habitacaoCtrl.isValid) return 4;
    if (!alimentacaoCtrl.isValid) return 5;
    return null;
  }

  /// Exibe os erros obrigatórios em TODAS as dimensões (item 14/16).
  void markAllErrors() {
    educacaoCtrl.setShowErrors(true);
    trabalhoCtrl.setShowErrors(true);
    saneamentoCtrl.setShowErrors(true);
    saudeCtrl.setShowErrors(true);
    habitacaoCtrl.setShowErrors(true);
    alimentacaoCtrl.setShowErrors(true);
  }

  /// Exibe os erros obrigatórios somente na dimensão do passo [step].
  void markStepErrors(int step) {
    switch (step) {
      case 0:
        educacaoCtrl.setShowErrors(true);
      case 1:
        trabalhoCtrl.setShowErrors(true);
      case 2:
        saneamentoCtrl.setShowErrors(true);
      case 3:
        saudeCtrl.setShowErrors(true);
      case 4:
        habitacaoCtrl.setShowErrors(true);
      case 5:
        alimentacaoCtrl.setShowErrors(true);
    }
  }

  /// Remove os erros obrigatórios da dimensão do passo [step] (ao avançar).
  void clearStepErrors(int step) {
    switch (step) {
      case 0:
        educacaoCtrl.setShowErrors(false);
      case 1:
        trabalhoCtrl.setShowErrors(false);
      case 2:
        saneamentoCtrl.setShowErrors(false);
      case 3:
        saudeCtrl.setShowErrors(false);
      case 4:
        habitacaoCtrl.setShowErrors(false);
      case 5:
        alimentacaoCtrl.setShowErrors(false);
    }
  }

  List<Map<String, String>> generateSummary() {
    final data = consolidatedData;
    return [
      {
        'categoria': 'Educação',
        'Escolaridade': _label(
          data.educacao.escolaridade,
          Escolaridade.labelOf,
        ),
        'Estuda atualmente': _simNaoNullable(data.educacao.estuda),
        'Situação dos estudos na gestação': _label(
          data.educacao.situacaoEstudosGestacao,
          SituacaoEstudosGestacao.labelOf,
        ),
        'Dificuldades de acesso à educação': _join(
          data.educacao.dificuldadesEducacao,
          DificuldadeEducacao.labelOf,
        ),
        'Entende orientações de saúde': _simNaoNullable(
          data.educacao.entendeOrientacoes,
        ),
        'Curso profissionalizante ou de qualificação': _simNaoNullable(
          data.educacao.fezCursoQualificacaoProfissional,
        ),
      },
      {
        'categoria': 'Trabalho e Renda',
        'Está empregada': _simNaoNullable(data.trabalho.empregado),
        'Faixa de renda familiar': _label(
          data.trabalho.faixaRenda,
          FaixaRenda.labelOf,
        ),
        if (data.trabalho.empregado == true) ...{
          'Tipo de emprego': _label(
            data.trabalho.tipoEmprego,
            TipoEmprego.labelOf,
          ),
          'Permite pré-natal': _simNaoNullable(data.trabalho.permitePreNatal),
          'Ambiente seguro': _simNaoNullable(data.trabalho.ambienteSeguro),
          'Tem pausas adequadas': _simNaoNullable(data.trabalho.temPausas),
          'Benefícios': _joinNullable(
            data.trabalho.beneficiosTrabalho,
            BeneficioTrabalho.labelOf,
          ),
        } else if (data.trabalho.empregado == false) ...{
          'Motivo desemprego': _label(
            data.trabalho.motivoDesemprego,
            MotivoDesemprego.labelOf,
          ),
        },
        'Recebe benefício social': _simNaoNullable(
          data.trabalho.recebeBeneficioSocial,
        ),
        'Impacto da gestação no trabalho': _label(
          data.trabalho.impactoGestacaoTrabalho,
          ImpactoGestacaoTrabalho.labelOf,
        ),
      },
      {
        'categoria': 'Saneamento Básico',
        'Fonte de água': _label(data.saneamento.fonteAgua, FonteAgua.labelOf),
        'Interrupções de água': _simNaoNullable(
          data.saneamento.interrupcoesAgua,
        ),
        'Destino do esgoto': _label(
          data.saneamento.esgotamentoSanitario,
          EsgotamentoSanitario.labelOf,
        ),
        'Regularidade da coleta de lixo': _label(
          data.saneamento.frequenciaColetaLixo,
          FrequenciaColetaLixo.labelOf,
        ),
        if (data.saneamento.frequenciaColetaLixo !=
            FrequenciaColetaLixo.regular.code)
          'Destinação do lixo sem coleta': _label(
            data.saneamento.destinoLixoSemColeta,
            DestinoLixoSemColeta.labelOf,
          ),
        'Problema de saúde por água': _simNaoNullable(
          data.saneamento.preocupacaoAgua,
        ),
        'Cuidados contra vetores': _join(
          data.saneamento.cuidadosVetores,
          CuidadoVetor.labelOf,
        ),
      },
      {
        'categoria': 'Saúde',
        'Distância da UBS': _label(
          data.saude.distanciaUBS,
          DistanciaUBS.labelOf,
        ),
        'Faltou consulta': _simNaoNullable(data.saude.faltouConsulta),
        'Como chega à UBS': _label(data.saude.acessoUBS, AcessoUBS.labelOf),
        'Cadastrada na UBS': _simNaoNullable(data.saude.cadastradaUBS),
        'Serviços de pré-natal': _join(
          data.saude.servicosPreNatal,
          ServicoPreNatal.labelOf,
        ),
        'Exames completos': _simNaoNullable(data.saude.examesPreNatalCompletos),
        'Vacinas em dia': _simNaoNullable(data.saude.vacinasEmDia),
        'Avaliação do pré-natal': _label(
          data.saude.avaliacaoPreNatal,
          AvaliacaoPreNatal.labelOf,
        ),
        'Dificuldades de acesso à saúde': _join(
          data.saude.dificuldadesSaude,
          DificuldadeSaude.labelOf,
        ),
      },
      {
        'categoria': 'Habitação',
        'Tipo de moradia': _label(
          data.habitacao.tipoMoradia,
          TipoMoradia.labelOf,
        ),
        'Material da moradia': _label(
          data.habitacao.materialMoradia,
          MaterialMoradia.labelOf,
        ),
        'Nº de pessoas na casa': data.habitacao.numeroPessoas.toString(),
        'Nº de cômodos': data.habitacao.numeroComodos.toString(),
        'Cômodos usados para dormir': data.habitacao.numeroDormitorios
            .toString(),
        'Itens da residência': _join(
          data.habitacao.itensResidencia,
          ItemResidencia.labelOf,
        ),
        'Segurança da residência': _label(
          data.habitacao.segurancaResidencia,
          SegurancaResidencia.labelOf,
        ),
        'Melhorias desejadas': _join(
          data.habitacao.melhoriasDesejadas,
          MelhoriaMoradia.labelOf,
        ),
        'Fácil acesso à saúde': _simNaoNullable(
          data.habitacao.facilAcessoSaude,
        ),
      },
      {
        'categoria': 'Alimentação',
        'Refeições por dia': _label(
          data.alimentacao.refeicoesPorDia,
          RefeicoesPorDia.labelOf,
        ),
        'Deixou de comer por falta de dinheiro': _simNaoNullable(
          data.alimentacao.deixouDeComerFaltaDinheiro,
        ),
        'Alimentos consumidos': _join(
          data.alimentacao.alimentosConsumidos,
          AlimentoConsumido.labelOf,
        ),
        'Origem dos alimentos': _join(
          data.alimentacao.fonteAlimentos,
          FonteAlimentos.labelOf,
        ),
        'Mudança na gestação': _simNaoNullable(
          data.alimentacao.mudancaAlimentacaoGestacao,
        ),
        'Usa suplementos': _simNaoNullable(data.alimentacao.usaSuplementos),
        'Avaliação da alimentação': _label(
          data.alimentacao.avaliacaoAlimentacao,
          AvaliacaoAlimentacao.labelOf,
        ),
      },
    ];
  }

  String _simNaoNullable(bool? value) {
    if (value == null) return 'Não informado';
    return value ? 'Sim' : 'Não';
  }

  String _label(String? code, String Function(String?) labelOf) {
    if (code == null || code.isEmpty) return 'Não informado';
    return labelOf(code);
  }

  String _join(List<String> codes, String Function(String?) labelOf) {
    if (codes.isEmpty) return 'Nenhuma';
    return codes.map((c) => labelOf(c)).join(', ');
  }

  String _joinNullable(List<String>? codes, String Function(String?) labelOf) {
    if (codes == null || codes.isEmpty) return 'Não informado';
    return codes.map((c) => labelOf(c)).join(', ');
  }
}
