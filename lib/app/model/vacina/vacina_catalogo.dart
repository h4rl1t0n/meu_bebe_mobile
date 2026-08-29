/// Catálogo canônico de vacinas do pré-natal (FASE 9D).
///
/// Separa o CATÁLOGO VISUAL/CANÔNICO (fixo, 7 itens) do REGISTRO PERSISTIDO NA
/// API (`VacinaModel`). O elo é o [VacinaCatalogoItem.nome]: um identificador
/// semântico estável ("HB_1", "dTpa") que casa 1:1 com `VacinaModel.nome`.
///
/// NUNCA usar o `id` (UUID) nem a posição/índice para decidir qual vacina é
/// qual — o UUID é identidade técnica da ocorrência e a ordem da API pode
/// diferir da ordem de exibição.
class VacinaCatalogoItem {
  final String nome;
  final String titulo;
  final String info;

  /// `true` = pertence ao grupo "20ª semana até 45 dias pós-parto" (dTpa);
  /// `false` = grupo "Qualquer tempo" (Hepatite B e dT).
  final bool tpa;

  const VacinaCatalogoItem({
    required this.nome,
    required this.titulo,
    required this.info,
    this.tpa = false,
  });
}

abstract final class VacinaCatalogo {
  static const itens = <VacinaCatalogoItem>[
    VacinaCatalogoItem(
      nome: 'HB_1',
      titulo: 'Hepatite B (HB - recombinante) (Dose 1)',
      info:
          'Essa vacina protege contra Hepatite B. Pode ser tomada em qualquer '
          'tempo do pré-natal, precisando de três doses.',
    ),
    VacinaCatalogoItem(
      nome: 'HB_2',
      titulo: 'Hepatite B (HB - recombinante) (Dose 2)',
      info:
          'Essa vacina protege contra Hepatite B. Pode ser tomada em qualquer '
          'tempo do pré-natal, precisando de três doses.',
    ),
    VacinaCatalogoItem(
      nome: 'HB_3',
      titulo: 'Hepatite B (HB - recombinante) (Dose 3)',
      info:
          'Essa vacina protege contra Hepatite B. Pode ser tomada em qualquer '
          'tempo do pré-natal, precisando de três doses.',
    ),
    VacinaCatalogoItem(
      nome: 'dT_1',
      titulo: 'Difteria e Tétano (dT) (Dose 1)',
      info:
          'Essa vacina protege contra Difteria e Tétano. Pode ser tomada em '
          'qualquer tempo do pré-natal, precisando de três doses.',
    ),
    VacinaCatalogoItem(
      nome: 'dT_2',
      titulo: 'Difteria e Tétano (dT) (Dose 2)',
      info:
          'Essa vacina protege contra Difteria e Tétano. Pode ser tomada em '
          'qualquer tempo do pré-natal, precisando de três doses.',
    ),
    VacinaCatalogoItem(
      nome: 'dT_3',
      titulo: 'Difteria e Tétano (dT) (Dose 3)',
      info:
          'Essa vacina protege contra Difteria e Tétano. Pode ser tomada em '
          'qualquer tempo do pré-natal, precisando de três doses.',
    ),
    VacinaCatalogoItem(
      nome: 'dTpa',
      titulo: 'Vacina Difteria, Tétano, Pertussis (dTpa - acelular)',
      info:
          'Essa vacina protege contra Difteria, Tétano e Coqueluche. '
          'Recomenda-se tomá-la a partir da 20ª semana da gravidez ou o mais '
          'breve possível em até 45 dias pós-parto.',
      tpa: true,
    ),
  ];
}
