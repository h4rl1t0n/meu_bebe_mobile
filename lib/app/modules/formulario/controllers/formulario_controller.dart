import 'package:mobx/mobx.dart';

import '../catalog/alimentacao_options.dart';
import '../catalog/educacao_options.dart';
import '../catalog/habitacao_options.dart';
import '../catalog/saneamento_options.dart';
import '../catalog/saude_options.dart';
import '../catalog/trabalho_options.dart';
import '../models/formulario_data.dart';
import '../submodules/alimentacao/alimentacao_controller.dart';
import '../submodules/educacao/educacao_controller.dart';
import '../submodules/habitacao/habitacao_controller.dart';
import '../submodules/saneamento/saneamento_controller.dart';
import '../submodules/saude/saude_controller.dart';
import '../submodules/trabalho/trabalho_controller.dart';

part 'formulario_controller.g.dart';

class FormularioController = FormularioControllerBase with _$FormularioController;

abstract class FormularioControllerBase with Store {
  final EducacaoController educacaoCtrl;
  final TrabalhoController trabalhoCtrl;
  final SaneamentoController saneamentoCtrl;
  final SaudeController saudeCtrl;
  final HabitacaoController habitacaoCtrl;
  final AlimentacaoController alimentacaoCtrl;

  FormularioControllerBase({
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
  bool loading = false;

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

  @action
  void setLoading(bool value) {
    loading = value;
  }

  @action
  Future<bool> enviarFormulario() async {
    loading = true;
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } finally {
      loading = false;
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

  List<Map<String, String>> generateSummary() {
    final data = consolidatedData;
    return [
      {
        'categoria': 'Educação',
        'Escolaridade': _label(data.educacao.escolaridade, Escolaridade.labelOf),
        'Estuda atualmente': _simNao(data.educacao.estuda),
        'Interrompeu estudos pela gestação': _simNao(data.educacao.interrompeuEstudos),
        'Dificuldades de acesso à educação': _join(data.educacao.dificuldadesEducacao, DificuldadeEducacao.labelOf),
        'Entende orientações de saúde': _simNao(data.educacao.entendeOrientacoes),
        'Curso extracurricular': _simNao(data.educacao.fezCursoExtracurricular),
      },
      {
        'categoria': 'Trabalho e Renda',
        'Está empregada': _simNao(data.trabalho.empregado),
        'Faixa de renda familiar': _label(data.trabalho.faixaRenda, FaixaRenda.labelOf),
        if (data.trabalho.empregado) ...{
          'Tipo de emprego': _label(data.trabalho.tipoEmprego, TipoEmprego.labelOf),
          'Permite pré-natal': _simNaoNullable(data.trabalho.permitePreNatal),
          'Ambiente seguro': _simNaoNullable(data.trabalho.ambienteSeguro),
          'Tem pausas adequadas': _simNaoNullable(data.trabalho.temPausas),
          'Benefícios': _joinNullable(data.trabalho.beneficiosTrabalho, BeneficioTrabalho.labelOf),
        } else ...{
          'Motivo desemprego': _label(data.trabalho.motivoDesemprego, MotivoDesemprego.labelOf),
        },
        'Recebe benefício social': _simNaoNullable(data.trabalho.recebeBeneficioSocial),
        'Impacto da gestação no trabalho': _label(
          data.trabalho.impactoGestacaoTrabalho,
          ImpactoGestacaoTrabalho.labelOf,
        ),
      },
      {
        'categoria': 'Saneamento Básico',
        'Fonte de água': _label(data.saneamento.fonteAgua, FonteAgua.labelOf),
        'Interrupções de água': _simNao(data.saneamento.interrupcoesAgua),
        'Destino do esgoto': _label(data.saneamento.esgotamentoSanitario, EsgotamentoSanitario.labelOf),
        'Regularidade da coleta de lixo': _label(data.saneamento.frequenciaColetaLixo, FrequenciaColetaLixo.labelOf),
        if (data.saneamento.frequenciaColetaLixo != FrequenciaColetaLixo.regular.code)
          'Destinação do lixo sem coleta': _label(data.saneamento.destinoLixoSemColeta, DestinoLixoSemColeta.labelOf),
        'Problema de saúde por água': _simNao(data.saneamento.preocupacaoAgua),
        'Cuidados contra vetores': _join(data.saneamento.cuidadosVetores, CuidadoVetor.labelOf),
      },
      {
        'categoria': 'Saúde',
        'Distância da UBS': _label(data.saude.distanciaUBS, DistanciaUBS.labelOf),
        'Faltou consulta': _simNao(data.saude.faltouConsulta),
        'Como chega à UBS': _label(data.saude.acessoUBS, AcessoUBS.labelOf),
        'Cadastrada na UBS': _simNaoNullable(data.saude.cadastradaUBS),
        'Serviços de pré-natal': _join(data.saude.servicosPreNatal, ServicoPreNatal.labelOf),
        'Exames completos': _simNao(data.saude.examesPreNatalCompletos),
        'Vacinas em dia': _simNao(data.saude.vacinasEmDia),
        'Avaliação do pré-natal': _label(data.saude.avaliacaoPreNatal, AvaliacaoPreNatal.labelOf),
        'Dificuldades de acesso à saúde': _join(data.saude.dificuldadesSaude, DificuldadeSaude.labelOf),
      },
      {
        'categoria': 'Habitação',
        'Tipo de moradia': _label(data.habitacao.tipoMoradia, TipoMoradia.labelOf),
        'Nº de pessoas na casa': data.habitacao.numeroPessoas.toString(),
        'Nº de cômodos': data.habitacao.numeroComodos.toString(),
        'Itens da residência': _join(data.habitacao.itensResidencia, ItemResidencia.labelOf),
        'Segurança estrutural': _label(data.habitacao.segurancaEstrutural, SegurancaResidencia.labelOf),
        'Melhorias desejadas': data.habitacao.melhoriasDesejadas ?? 'Não informado',
        'Fácil acesso à saúde': _simNao(data.habitacao.facilAcessoSaude),
      },
      {
        'categoria': 'Alimentação',
        'Refeições por dia': _label(data.alimentacao.refeicoesPorDia, RefeicoesPorDia.labelOf),
        'Insegurança alimentar': _simNao(data.alimentacao.insegurancaAlimentar),
        'Alimentos consumidos': _join(data.alimentacao.alimentosConsumidos, AlimentoConsumido.labelOf),
        'Origem dos alimentos': _label(data.alimentacao.fonteAlimentos, FonteAlimentos.labelOf),
        'Mudança na gestação': _simNao(data.alimentacao.mudancaAlimentacaoGestacao),
        'Usa suplementos': _simNao(data.alimentacao.usaSuplementos),
        'Avaliação da alimentação': _label(data.alimentacao.avaliacaoAlimentacao, AvaliacaoAlimentacao.labelOf),
      },
    ];
  }

  String _simNao(bool value) => value ? 'Sim' : 'Não';

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
