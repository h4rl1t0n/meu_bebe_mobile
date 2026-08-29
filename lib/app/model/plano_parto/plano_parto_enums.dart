/// Enums estáveis do domínio PLANO DE PARTO (FASE 9E).
///
/// O backend trafega STRINGS ESTÁVEIS (nunca ordinal/`.index`). Cada enum abaixo
/// carrega o `value` canônico do contrato e um `label` de exibição, com um
/// `fromValue` tolerante que cai em ``naoSei`` (o domínio NUNCA inventa valor
/// clínico — o "não informado" é preservado como ``nao_sei``).
library;

/// Tri-state genérico (Alternatives / Anesthesia / VaginalCut /
/// SkinBabyContact / BreastfeedFirstHour / NeedPainRelief).
enum TriState {
  sim('sim', 'Sim'),
  nao('nao', 'Não'),
  naoSei('nao_sei', 'Não sei');

  const TriState(this.value, this.label);

  final String value;
  final String label;

  static TriState fromValue(Object? value) => TriState.values.firstWhere(
    (e) => e.value == value,
    orElse: () => TriState.naoSei,
  );
}

/// Via de parto (BirthWay).
enum ViaParto {
  vaginal('vaginal', 'Vaginal'),
  cesarea('cesarea', 'Cesárea'),
  naoSei('nao_sei', 'Não sei');

  const ViaParto(this.value, this.label);

  final String value;
  final String label;

  static ViaParto fromValue(Object? value) => ViaParto.values.firstWhere(
    (e) => e.value == value,
    orElse: () => ViaParto.naoSei,
  );
}

/// Quem corta o cordão / quem dá o primeiro banho (WhoCut / FirstBath).
enum ActorChoice {
  profissional('profissional', 'Profissional'),
  acompanhante('acompanhante', 'Acompanhante'),
  eu('eu', 'Eu'),
  naoSei('nao_sei', 'Não sei');

  const ActorChoice(this.value, this.label);

  final String value;
  final String label;

  static ActorChoice fromValue(Object? value) => ActorChoice.values.firstWhere(
    (e) => e.value == value,
    orElse: () => ActorChoice.naoSei,
  );
}

/// Posição preferida para o parto (Positions).
enum PosicaoParto {
  deitada('deitada', 'Deitada'),
  sentada('sentada', 'Sentada'),
  agachada('agachada', 'Agachada'),
  deLado('de_lado', 'De lado'),
  deJoelhos('de_joelhos', 'De joelhos'),
  emPe('em_pe', 'Em pé'),
  naoSei('nao_sei', 'Não sei'),
  outra('outra', 'Outra');

  const PosicaoParto(this.value, this.label);

  final String value;
  final String label;

  /// `null` para valor ausente/vazio (posição é opcional no contrato).
  static PosicaoParto? fromValue(Object? value) {
    if (value == null) return null;
    for (final e in PosicaoParto.values) {
      if (e.value == value) return e;
    }
    return null;
  }
}
