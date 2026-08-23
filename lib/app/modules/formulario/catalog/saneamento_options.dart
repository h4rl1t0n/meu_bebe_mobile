/// Opções canônicas da dimensão Saneamento Básico.
enum FonteAgua {
  redePublica('rede_publica', 'Rede pública'),
  pocoNascente('poco_nascente', 'Poço ou nascente'),
  cisterna('cisterna', 'Cisterna'),
  carroPipa('carro_pipa', 'Carro-pipa'),
  outra('outra', 'Outra fonte');

  const FonteAgua(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

enum EsgotamentoSanitario {
  redeColetora('rede_coletora', 'Rede coletora'),
  ceuAberto('ceu_aberto', 'Céu aberto/rio'),
  fossaSeptica('fossa_septica', 'Fossa séptica'),
  outro('outro', 'Outro');

  const EsgotamentoSanitario(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

/// Regularidade com que o serviço de coleta recolhe o lixo da residência.
enum FrequenciaColetaLixo {
  regular('regular', 'Regular'),
  irregular('irregular', 'Irregular'),
  naoPossui('nao_possui', 'Não possui coleta');

  const FrequenciaColetaLixo(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

/// Principal forma de destinação do lixo quando não há coleta adequada.
///
/// Aplicável quando [FrequenciaColetaLixo] é `irregular` ou `nao_possui`;
/// para `regular`, o campo é tratado como não aplicável (permanece `null`).
///
/// `aguardaProximaColeta` só faz sentido quando existe serviço de coleta
/// (mesmo que irregular): para `nao_possui`, não há próxima coleta a aguardar,
/// então essa opção não é oferecida.
enum DestinoLixoSemColeta {
  aguardaProximaColeta('aguarda_proxima_coleta', 'Armazena o lixo até a próxima coleta'),
  queima('queima', 'Queima o lixo'),
  enterra('enterra', 'Enterra o lixo'),
  terrenoBaldio('terreno_baldio', 'Joga em terreno baldio'),
  outro('outro', 'Outro');

  const DestinoLixoSemColeta(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}

/// Cuidados adotados para evitar mosquitos e outros vetores (múltipla escolha).
///
/// `semCuidados` é mutuamente exclusiva: quando selecionada, as demais opções
/// são removidas (regra implementada no controller).
enum CuidadoVetor {
  eliminaAguaParada('elimina_agua_parada', 'Elimina água parada'),
  mantemReservatoriosTampados('mantem_reservatorios_tampados', 'Mantém reservatórios tampados'),
  usaRepelente('usa_repelente', 'Usa repelente'),
  usaMosquiteiroTelas('usa_mosquiteiro_telas', 'Usa mosquiteiros ou telas'),
  mantemAmbienteLimpo('mantem_ambiente_limpo', 'Mantém quintal/ambiente limpo'),
  usaInseticida('usa_inseticida', 'Usa inseticida'),
  semCuidados('sem_cuidados', 'Não realiza cuidados específicos'),
  outro('outro', 'Outro');

  const CuidadoVetor(this.code, this.label);

  final String code;
  final String label;

  static String labelOf(String? code) {
    for (final option in values) {
      if (option.code == code) return option.label;
    }
    return code ?? '';
  }
}
