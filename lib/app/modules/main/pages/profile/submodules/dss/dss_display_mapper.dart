import '../../../../../../modules/formulario/catalog/alimentacao_options.dart';
import '../../../../../../modules/formulario/catalog/educacao_options.dart';
import '../../../../../../modules/formulario/catalog/habitacao_options.dart';
import '../../../../../../modules/formulario/catalog/saneamento_options.dart';
import '../../../../../../modules/formulario/catalog/saude_options.dart';
import '../../../../../../modules/formulario/catalog/trabalho_options.dart';

/// Mapeamento centralizado de EXIBIÇÃO (somente leitura) das 48 variáveis do
/// Schema DSS 1.13.
///
/// Converte identificadores técnicos (`acesso_ubs`, `sem_instrucao`) em texto
/// humano para a tela de detalhe da avaliação. É camada de apresentação pura:
/// NÃO altera serialização, contrato HTTP, schema, `toMap()`/`fromMap()` nem
/// qualquer dado já persistido.
///
/// Regras de formatação:
///   - booleano: `true` → "Sim", `false` → "Não" (nunca "true"/"1"/"0");
///   - categórica: código canônico → rótulo do enum do formulário;
///   - múltipla escolha: lista de códigos → lista de rótulos (bullets/chips);
///   - `null` em campo condicional → "Não se aplica";
///   - `null` em campo comum → "Não informado".
class DssDisplayMapper {
  const DssDisplayMapper._();

  /// Ordem canônica das dimensões (mesma ordem de leitura do questionário).
  static const List<String> dimensionOrder = <String>[
    'saude',
    'educacao',
    'trabalho',
    'saneamento',
    'habitacao',
    'alimentacao',
  ];

  static const Map<String, String> dimensionNames = <String, String>{
    'saude': 'Saúde',
    'educacao': 'Educação',
    'trabalho': 'Trabalho e Renda',
    'saneamento': 'Saneamento',
    'habitacao': 'Habitação',
    'alimentacao': 'Alimentação',
  };

  /// Rótulo humano de uma dimensão. Fallback: a própria chave.
  static String labelForDimension(String dimension) =>
      dimensionNames[dimension] ?? dimension;

  /// Ordem dos campos dentro de cada dimensão, igual à ordem das perguntas no
  /// questionário (não à ordem de iteração do Map).
  static const Map<String, List<String>> _fieldOrder = <String, List<String>>{
    'saude': <String>[
      'distancia_ubs',
      'faltou_consulta',
      'acesso_ubs',
      'cadastrada_ubs',
      'servicos_pre_natal',
      'exames_pre_natal_completos',
      'vacinas_em_dia',
      'avaliacao_pre_natal',
      'dificuldades_saude',
    ],
    'educacao': <String>[
      'estuda_atualmente',
      'escolaridade',
      'situacao_estudos_gestacao',
      'dificuldades_educacao',
      'entende_orientacoes_saude',
      'fez_curso_qualificacao_profissional',
    ],
    'trabalho': <String>[
      'empregado',
      'tipo_emprego',
      'trabalho_permite_pre_natal',
      'ambiente_trabalho_seguro',
      'tem_pausas_descanso',
      'beneficios_trabalho',
      'motivo_desemprego',
      'faixa_renda',
      'recebe_beneficio_social',
      'impacto_gestacao_trabalho',
    ],
    'saneamento': <String>[
      'fonte_agua',
      'interrupcoes_agua',
      'esgotamento_sanitario',
      'frequencia_coleta_lixo',
      'destino_lixo_sem_coleta',
      'problema_saude_agua',
      'cuidados_vetores',
    ],
    'habitacao': <String>[
      'tipo_moradia',
      'material_moradia',
      'numero_pessoas',
      'numero_comodos',
      'numero_dormitorios',
      'itens_residencia',
      'seguranca_residencia',
      'melhorias_desejadas',
      'facil_acesso_saude',
    ],
    'alimentacao': <String>[
      'refeicoes_por_dia',
      'deixou_de_comer_falta_dinheiro',
      'alimentos_consumidos',
      'fonte_alimentos',
      'mudanca_alimentacao_gestacao',
      'usa_suplementos',
      'avaliacao_alimentacao',
    ],
  };

  /// Redação das perguntas do formulário, reutilizada como rótulo de campo.
  static const Map<String, String> _fieldLabels = <String, String>{
    // Saúde
    'distancia_ubs': 'Há uma UBS próxima da sua casa?',
    'faltou_consulta': 'Já faltou a alguma consulta por dificuldade de transporte ou trabalho?',
    'acesso_ubs': 'Como você costuma chegar à UBS?',
    'cadastrada_ubs': 'Você possui cadastro em uma Unidade Básica de Saúde (UBS)?',
    'servicos_pre_natal': 'Quais serviços de pré-natal você utiliza?',
    'exames_pre_natal_completos': 'Realizou todos os exames solicitados no pré-natal?',
    'vacinas_em_dia': 'Tomou todas as vacinas indicadas para gestantes?',
    'avaliacao_pre_natal': 'Como avalia o atendimento de pré-natal?',
    'dificuldades_saude': 'Quais dificuldades você enfrenta para acessar/utilizar os serviços de saúde?',
    // Educação
    'estuda_atualmente': 'Está estudando atualmente?',
    'escolaridade': 'Qual seu grau de escolaridade?',
    'situacao_estudos_gestacao': 'Qual situação melhor descreve seus estudos durante esta gestação?',
    'dificuldades_educacao': 'Que dificuldades enfrenta no acesso à educação?',
    'entende_orientacoes_saude': 'Você consegue entender bem as orientações dos profissionais de saúde?',
    'fez_curso_qualificacao_profissional': 'Faz ou fez algum curso profissionalizante ou de qualificação?',
    // Trabalho e Renda
    'empregado': 'Você está trabalhando atualmente?',
    'tipo_emprego': 'Qual o tipo do seu emprego?',
    'trabalho_permite_pre_natal': 'Seu trabalho permite ir às consultas de pré-natal?',
    'ambiente_trabalho_seguro': 'Seu ambiente de trabalho é seguro para gestante?',
    'tem_pausas_descanso': 'Tem pausas para descanso e alimentação adequada?',
    'beneficios_trabalho': 'Quais benefícios você recebe?',
    'motivo_desemprego': 'Por que não está trabalhando atualmente?',
    'faixa_renda': 'Qual é a faixa de renda mensal familiar?',
    'recebe_beneficio_social': 'Já solicitou ou recebe algum benefício social?',
    'impacto_gestacao_trabalho': 'Como a gestação afetou sua situação de trabalho?',
    // Saneamento
    'fonte_agua': 'Qual a principal fonte de água da sua residência?',
    'interrupcoes_agua': 'Há interrupções frequentes no fornecimento de água?',
    'esgotamento_sanitario': 'Como é o esgotamento sanitário na sua residência?',
    'frequencia_coleta_lixo': 'Com que regularidade o lixo da sua residência é coletado pelo serviço de coleta?',
    'destino_lixo_sem_coleta': 'Quando o lixo não é recolhido pelo serviço de coleta, qual é a principal forma de destinação?',
    'problema_saude_agua': 'Já teve algum problema de saúde por conta da água?',
    'cuidados_vetores': 'Quais cuidados você adota para evitar mosquitos/vetores?',
    // Habitação
    'tipo_moradia': 'Tipo de moradia',
    'material_moradia': 'Material predominante das paredes',
    'numero_pessoas': 'Nº de pessoas na casa',
    'numero_comodos': 'Nº de cômodos',
    'numero_dormitorios': 'Cômodos usados para dormir',
    'itens_residencia': 'Quais destes itens sua casa possui?',
    'seguranca_residencia': 'Como você avalia a segurança da sua moradia?',
    'melhorias_desejadas': 'Quais melhorias gostaria de fazer na sua moradia?',
    'facil_acesso_saude': 'Tem fácil acesso a serviços de saúde a partir da sua residência?',
    // Alimentação
    'refeicoes_por_dia': 'Quantas refeições completas você faz por dia?',
    'deixou_de_comer_falta_dinheiro': 'Nos últimos 3 meses, deixou de comer por falta de dinheiro?',
    'alimentos_consumidos': 'Quais alimentos você consome regularmente?',
    'fonte_alimentos': 'De onde vêm os alimentos que você consome?',
    'mudanca_alimentacao_gestacao': 'Sua alimentação mudou durante a gestação?',
    'usa_suplementos': 'Está tomando suplementos vitamínicos ou de ferro?',
    'avaliacao_alimentacao': 'Como você avalia sua alimentação durante a gestação?',
  };

  /// Campos condicionais: `null` significa "não se aplica" (o bloco da pergunta
  /// não era exibido para aquela resposta), e não "não informado".
  static const Set<String> _conditionalFields = <String>{
    'tipo_emprego',
    'trabalho_permite_pre_natal',
    'ambiente_trabalho_seguro',
    'tem_pausas_descanso',
    'beneficios_trabalho',
    'motivo_desemprego',
    'destino_lixo_sem_coleta',
  };

  /// Resolvedores de código canônico → rótulo, reutilizando os enums do
  /// formulário (que já centralizam `code`/`label`).
  static final Map<String, String Function(String?)> _valueLabelers =
      <String, String Function(String?)>{
    'distancia_ubs': DistanciaUBS.labelOf,
    'acesso_ubs': AcessoUBS.labelOf,
    'servicos_pre_natal': ServicoPreNatal.labelOf,
    'avaliacao_pre_natal': AvaliacaoPreNatal.labelOf,
    'dificuldades_saude': DificuldadeSaude.labelOf,
    'escolaridade': Escolaridade.labelOf,
    'situacao_estudos_gestacao': SituacaoEstudosGestacao.labelOf,
    'dificuldades_educacao': DificuldadeEducacao.labelOf,
    'tipo_emprego': TipoEmprego.labelOf,
    'faixa_renda': FaixaRenda.labelOf,
    'beneficios_trabalho': BeneficioTrabalho.labelOf,
    'motivo_desemprego': MotivoDesemprego.labelOf,
    'impacto_gestacao_trabalho': ImpactoGestacaoTrabalho.labelOf,
    'fonte_agua': FonteAgua.labelOf,
    'esgotamento_sanitario': EsgotamentoSanitario.labelOf,
    'frequencia_coleta_lixo': FrequenciaColetaLixo.labelOf,
    'destino_lixo_sem_coleta': DestinoLixoSemColeta.labelOf,
    'cuidados_vetores': CuidadoVetor.labelOf,
    'tipo_moradia': TipoMoradia.labelOf,
    'material_moradia': MaterialMoradia.labelOf,
    'itens_residencia': ItemResidencia.labelOf,
    'seguranca_residencia': SegurancaResidencia.labelOf,
    'melhorias_desejadas': MelhoriaMoradia.labelOf,
    'refeicoes_por_dia': RefeicoesPorDia.labelOf,
    'alimentos_consumidos': AlimentoConsumido.labelOf,
    'fonte_alimentos': FonteAlimentos.labelOf,
    'avaliacao_alimentacao': AvaliacaoAlimentacao.labelOf,
  };

  /// Rótulo humano de uma pergunta/ campo. Fallback: a própria chave.
  static String labelForField(String field) => _fieldLabels[field] ?? field;

  /// Rótulo humano de um valor categórico/múltipla escolha. Fallback: o próprio
  /// código (mantém o valor visível mesmo que desconhecido).
  static String labelForValue(String field, String code) {
    final labeler = _valueLabelers[field];
    return labeler == null ? code : labeler(code);
  }

  /// Formata um booleano: `true` → "Sim", `false` → "Não".
  static String formatBoolean(bool value) => value ? 'Sim' : 'Não';

  /// Formata uma lista de códigos em lista de rótulos (uma linha por item).
  /// Lista vazia retorna vazia (o chamador decide o placeholder).
  static List<String> formatList(String field, List value) =>
      value.map((e) => labelForValue(field, e.toString())).toList();

  /// Formata um valor bruto em texto de exibição (não aplicável a listas, que
  /// devem usar [formatList] para renderização em bullets/chips).
  static String formatValue(String field, dynamic value) {
    if (value == null) {
      return _conditionalFields.contains(field) ? 'Não se aplica' : 'Não informado';
    }
    if (value is bool) return formatBoolean(value);
    if (value is num) return value.toString();
    if (value is List) {
      final items = formatList(field, value);
      return items.isEmpty ? 'Não informado' : items.join('\n');
    }
    return labelForValue(field, value.toString());
  }

  /// Chaves de campo de uma dimensão na ordem do questionário, seguidas de
  /// eventuais chaves desconhecidas (defensivo) presentes no mapa.
  static List<String> orderedFields(String dimension, Map<String, dynamic> fields) {
    final order = _fieldOrder[dimension] ?? const <String>[];
    final result = <String>[];
    final seen = <String>{};
    for (final key in order) {
      if (fields.containsKey(key)) {
        result.add(key);
        seen.add(key);
      }
    }
    for (final key in fields.keys) {
      if (!seen.contains(key)) result.add(key);
    }
    return result;
  }
}
