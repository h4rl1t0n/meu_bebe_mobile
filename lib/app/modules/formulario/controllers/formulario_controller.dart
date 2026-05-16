import 'package:mobx/mobx.dart';

import '../models/formulario_data.dart';
import '../submodules/educacao/educacao_controller.dart';
import '../submodules/trabalho/trabalho_controller.dart';
import '../submodules/saneamento/saneamento_controller.dart';
import '../submodules/saude/saude_controller.dart';
import '../submodules/habitacao/habitacao_controller.dart';
import '../submodules/alimentacao/alimentacao_controller.dart';

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
        'Escolaridade': data.educacao.escolaridade,
        'Estuda atualmente': data.educacao.estuda ? 'Sim' : 'Não',
        'Interrompeu estudos pela gestação': data.educacao.interrompeuEstudos ? 'Sim' : 'Não',
        'Dificuldades de acesso à educação': data.educacao.dificuldadesEscolares,
        'Entende orientações de saúde': data.educacao.entendeOrientacoes ? 'Sim' : 'Não',
        'Cursos extracurriculares': data.educacao.cursosExtracurriculares,
        'Expectativas educacionais': data.educacao.expectativasEducacionais,
      },
      {
        'categoria': 'Trabalho e Renda',
        'Está empregada': data.trabalho.empregado ? 'Sim' : 'Não',
        if (data.trabalho.empregado) ...{
          'Tipo de emprego': data.trabalho.tipoEmprego,
          'Faixa de renda': data.trabalho.faixaRenda,
          'Permite pré-natal': data.trabalho.permitePreNatal ? 'Sim' : 'Não',
          'Ambiente seguro': data.trabalho.ambienteSeguro ? 'Sim' : 'Não',
          'Tem pausas adequadas': data.trabalho.temPausas ? 'Sim' : 'Não',
          'Auxílio-maternidade': data.trabalho.recebeAuxilioMaternidade ? 'Sim' : 'Não',
          'Vale-transporte': data.trabalho.recebeValeTransporte ? 'Sim' : 'Não',
          'Vale-alimentação': data.trabalho.recebeValeAlimentacao ? 'Sim' : 'Não',
        } else ...{
          'Motivo desemprego': data.trabalho.motivoDesemprego,
          'Recebe benefício social': data.trabalho.recebeBeneficioSocial ? 'Sim' : 'Não',
        },
        'Impacto da gestação no trabalho': data.trabalho.impactoGestacaoTrabalho,
      },
      {
        'categoria': 'Saneamento Básico',
        'Fonte de água': data.saneamento.fonteAgua,
        'Interrupções de água': data.saneamento.interrupcoesAgua,
        'Destino do esgoto': data.saneamento.destinoEsgoto,
        'Coleta de lixo': data.saneamento.coletaLixo,
        'Problema de saúde por água': data.saneamento.preocupacaoAgua ? 'Sim' : 'Não',
        'Cuidados contra vetores': data.saneamento.cuidadosVetores,
      },
      {
        'categoria': 'Saúde',
        'Distância da UBS': data.saude.distanciaUBS,
        'Faltou consulta': data.saude.faltouConsulta ? 'Sim' : 'Não',
        'Como chega à UBS': data.saude.acessibilidadeUBS,
        'Cadastrada na UBS': data.saude.cadastradaUBS ? 'Sim' : 'Não',
        'Pré-natal médico': data.saude.preNatalMedico ? 'Sim' : 'Não',
        'Pré-natal enfermagem': data.saude.preNatalEnfermagem ? 'Sim' : 'Não',
        'Grupo de gestantes': data.saude.participaGrupoGestantes ? 'Sim' : 'Não',
        'Exames completos': data.saude.examesPreNatalCompletos ? 'Sim' : 'Não',
        'Vacinas em dia': data.saude.vacinasEmDia ? 'Sim' : 'Não',
        'Avaliação do pré-natal': data.saude.avaliacaoPreNatal,
        'Dificuldades de acesso à saúde': data.saude.dificuldadesSaude,
      },
      {
        'categoria': 'Habitação',
        'Tipo de moradia': data.habitacao.tipoMoradia,
        'Nº de pessoas na casa': data.habitacao.numeroPessoas.toString(),
        'Nº de cômodos': data.habitacao.numeroComodos.toString(),
        'Água encanada': data.habitacao.temAguaEncanada ? 'Sim' : 'Não',
        'Banheiro interno': data.habitacao.temBanheiro ? 'Sim' : 'Não',
        'Cozinha separada': data.habitacao.temCozinhaSeparada ? 'Sim' : 'Não',
        'Segurança estrutural': data.habitacao.segurancaEstrutural,
        'Melhorias desejadas': data.habitacao.melhoriasDesejadas,
        'Fácil acesso à saúde': data.habitacao.facilAcessoSaude ? 'Sim' : 'Não',
      },
      {
        'categoria': 'Alimentação',
        'Refeições por dia': data.alimentacao.refeicoesPorDia.toString(),
        'Insegurança alimentar': data.alimentacao.insegurancaAlimentar ? 'Sim' : 'Não',
        'Consome frutas/verduras': data.alimentacao.consomeFrutasVerduras ? 'Sim' : 'Não',
        'Consome carnes': data.alimentacao.consomeCarnes ? 'Sim' : 'Não',
        'Consome leite': data.alimentacao.consomeLeite ? 'Sim' : 'Não',
        'Consome feijão': data.alimentacao.consomeFeijao ? 'Sim' : 'Não',
        'Origem dos alimentos': data.alimentacao.fonteAlimentos,
        'Mudança na gestação': data.alimentacao.mudancaAlimentacaoGestacao ? 'Sim' : 'Não',
        'Usa suplementos': data.alimentacao.usaSuplementos ? 'Sim' : 'Não',
        'Avaliação da alimentação': data.alimentacao.avaliacaoAlimentacao,
      },
    ];
  }
}
