import 'plano_parto_enums.dart';

/// Modelo consolidado do domínio PLANO DE PARTO (FASE 9E).
///
/// As CINCO telas legadas (Expectativas, Momento do parto, Nascimento, Alívio da
/// dor, Observações) eram singletons SQLite independentes; agora são UM ÚNICO
/// recurso singleton por gestação na API. Este modelo carrega os 28 campos do
/// contrato como STRINGS ESTÁVEIS / bools — nunca ordinal. O `id` é `null` até o
/// primeiro PUT (o backend gera o UUID no upsert).
class PlanoPartoModel {
  final String? id;

  // ---- Expectativas (TriState) ----
  final String acompanhante;
  final String rasparPelosIntimos;
  final String lavagemIntestinal;
  final String ambientePoucaLuz;
  final String ouvirMusica;
  final String beberLiquidos;
  final String registrarFotosVideos;

  // ---- Momento do parto ----
  final String viaParto;
  final String anestesia;
  final String corteVaginal;
  final String? posicaoPreferida;
  final String? outraPosicao;

  // ---- Nascimento ----
  final String quemCortaCordao;
  final bool coletaCelulasTronco;
  final String contatoPeleAPele;
  final String amamentarPrimeiraHora;
  final bool restricoesAmamentacao;
  final String primeiroBanho;

  // ---- Alívio da dor ----
  final String querAlivioDor;
  final bool massagem;
  final bool exerciciosBola;
  final bool exerciciosRespiracao;
  final bool banhoChuveiro;
  final bool banhoBanheira;
  final bool acupuntura;
  final bool acupressao;
  final bool outroMetodo;

  // ---- Observações ----
  final String observacoes;

  const PlanoPartoModel({
    this.id,
    required this.acompanhante,
    required this.rasparPelosIntimos,
    required this.lavagemIntestinal,
    required this.ambientePoucaLuz,
    required this.ouvirMusica,
    required this.beberLiquidos,
    required this.registrarFotosVideos,
    required this.viaParto,
    required this.anestesia,
    required this.corteVaginal,
    this.posicaoPreferida,
    this.outraPosicao,
    required this.quemCortaCordao,
    required this.coletaCelulasTronco,
    required this.contatoPeleAPele,
    required this.amamentarPrimeiraHora,
    required this.restricoesAmamentacao,
    required this.primeiroBanho,
    required this.querAlivioDor,
    required this.massagem,
    required this.exerciciosBola,
    required this.exerciciosRespiracao,
    required this.banhoChuveiro,
    required this.banhoBanheira,
    required this.acupuntura,
    required this.acupressao,
    required this.outroMetodo,
    required this.observacoes,
  });

  /// Plano "vazio" — o estado antes do primeiro salvamento.
  ///
  /// Todos os tri-states nascem ``nao_sei`` (não informado — NUNCA convertido em
  /// ``nao``), os bools em `false`, as opcionais em `null` e observações em ``""``.
  factory PlanoPartoModel.empty() => const PlanoPartoModel(
    acompanhante: 'nao_sei',
    rasparPelosIntimos: 'nao_sei',
    lavagemIntestinal: 'nao_sei',
    ambientePoucaLuz: 'nao_sei',
    ouvirMusica: 'nao_sei',
    beberLiquidos: 'nao_sei',
    registrarFotosVideos: 'nao_sei',
    viaParto: 'nao_sei',
    anestesia: 'nao_sei',
    corteVaginal: 'nao_sei',
    quemCortaCordao: 'nao_sei',
    coletaCelulasTronco: false,
    contatoPeleAPele: 'nao_sei',
    amamentarPrimeiraHora: 'nao_sei',
    restricoesAmamentacao: false,
    primeiroBanho: 'nao_sei',
    querAlivioDor: 'nao_sei',
    massagem: false,
    exerciciosBola: false,
    exerciciosRespiracao: false,
    banhoChuveiro: false,
    banhoBanheira: false,
    acupuntura: false,
    acupressao: false,
    outroMetodo: false,
    observacoes: '',
  );

  static const _sentinel = Object();

  static String _triState(Object? value) => TriState.fromValue(value).value;
  static String _viaParto(Object? value) => ViaParto.fromValue(value).value;
  static String _actor(Object? value) => ActorChoice.fromValue(value).value;
  static String? _posicao(Object? value) =>
      PosicaoParto.fromValue(value)?.value;
  static bool _bool(Object? value) => value == true;
  static String _text(Object? value) => value is String ? value : '';

  /// Parse defensivo da resposta do backend.
  ///
  /// Campos ausentes/malformados caem no valor canônico "não informado"
  /// (``nao_sei``/`false`/`null`/``""``) — nunca quebra nem inventa valor.
  static PlanoPartoModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final id = data['id'];
    return PlanoPartoModel(
      id: id is String ? id : null,
      acompanhante: _triState(data['acompanhante']),
      rasparPelosIntimos: _triState(data['raspar_pelos_intimos']),
      lavagemIntestinal: _triState(data['lavagem_intestinal']),
      ambientePoucaLuz: _triState(data['ambiente_pouca_luz']),
      ouvirMusica: _triState(data['ouvir_musica']),
      beberLiquidos: _triState(data['beber_liquidos']),
      registrarFotosVideos: _triState(data['registrar_fotos_videos']),
      viaParto: _viaParto(data['via_parto']),
      anestesia: _triState(data['anestesia']),
      corteVaginal: _triState(data['corte_vaginal']),
      posicaoPreferida: _posicao(data['posicao_preferida']),
      outraPosicao: data['outra_posicao'] is String
          ? data['outra_posicao'] as String?
          : null,
      quemCortaCordao: _actor(data['quem_corta_cordao']),
      coletaCelulasTronco: _bool(data['coleta_celulas_tronco']),
      contatoPeleAPele: _triState(data['contato_pele_a_pele']),
      amamentarPrimeiraHora: _triState(data['amamentar_primeira_hora']),
      restricoesAmamentacao: _bool(data['restricoes_amamentacao']),
      primeiroBanho: _actor(data['primeiro_banho']),
      querAlivioDor: _triState(data['quer_alivio_dor']),
      massagem: _bool(data['massagem']),
      exerciciosBola: _bool(data['exercicios_bola']),
      exerciciosRespiracao: _bool(data['exercicios_respiracao']),
      banhoChuveiro: _bool(data['banho_chuveiro']),
      banhoBanheira: _bool(data['banho_banheira']),
      acupuntura: _bool(data['acupuntura']),
      acupressao: _bool(data['acupressao']),
      outroMetodo: _bool(data['outro_metodo']),
      observacoes: _text(data['observacoes']),
    );
  }

  /// Payload de escrita (PUT — full update) com as chaves do contrato.
  ///
  /// NUNCA inclui `id`, `gestacao_id` nem timestamps. `outra_posicao` vazia é
  /// normalizada para `null` (o backend faz o mesmo); observações vazias são
  /// permitidas (``""``).
  Map<String, dynamic> toWriteJson() {
    return {
      'acompanhante': acompanhante,
      'raspar_pelos_intimos': rasparPelosIntimos,
      'lavagem_intestinal': lavagemIntestinal,
      'ambiente_pouca_luz': ambientePoucaLuz,
      'ouvir_musica': ouvirMusica,
      'beber_liquidos': beberLiquidos,
      'registrar_fotos_videos': registrarFotosVideos,
      'via_parto': viaParto,
      'anestesia': anestesia,
      'corte_vaginal': corteVaginal,
      'posicao_preferida': posicaoPreferida,
      'outra_posicao': _normalizeOutra(outraPosicao),
      'quem_corta_cordao': quemCortaCordao,
      'coleta_celulas_tronco': coletaCelulasTronco,
      'contato_pele_a_pele': contatoPeleAPele,
      'amamentar_primeira_hora': amamentarPrimeiraHora,
      'restricoes_amamentacao': restricoesAmamentacao,
      'primeiro_banho': primeiroBanho,
      'quer_alivio_dor': querAlivioDor,
      'massagem': massagem,
      'exercicios_bola': exerciciosBola,
      'exercicios_respiracao': exerciciosRespiracao,
      'banho_chuveiro': banhoChuveiro,
      'banho_banheira': banhoBanheira,
      'acupuntura': acupuntura,
      'acupressao': acupressao,
      'outro_metodo': outroMetodo,
      'observacoes': observacoes,
    };
  }

  static String? _normalizeOutra(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  PlanoPartoModel copyWith({
    Object? id = _sentinel,
    String? acompanhante,
    String? rasparPelosIntimos,
    String? lavagemIntestinal,
    String? ambientePoucaLuz,
    String? ouvirMusica,
    String? beberLiquidos,
    String? registrarFotosVideos,
    String? viaParto,
    String? anestesia,
    String? corteVaginal,
    Object? posicaoPreferida = _sentinel,
    Object? outraPosicao = _sentinel,
    String? quemCortaCordao,
    bool? coletaCelulasTronco,
    String? contatoPeleAPele,
    String? amamentarPrimeiraHora,
    bool? restricoesAmamentacao,
    String? primeiroBanho,
    String? querAlivioDor,
    bool? massagem,
    bool? exerciciosBola,
    bool? exerciciosRespiracao,
    bool? banhoChuveiro,
    bool? banhoBanheira,
    bool? acupuntura,
    bool? acupressao,
    bool? outroMetodo,
    String? observacoes,
  }) {
    return PlanoPartoModel(
      id: identical(id, _sentinel) ? this.id : id as String?,
      acompanhante: acompanhante ?? this.acompanhante,
      rasparPelosIntimos: rasparPelosIntimos ?? this.rasparPelosIntimos,
      lavagemIntestinal: lavagemIntestinal ?? this.lavagemIntestinal,
      ambientePoucaLuz: ambientePoucaLuz ?? this.ambientePoucaLuz,
      ouvirMusica: ouvirMusica ?? this.ouvirMusica,
      beberLiquidos: beberLiquidos ?? this.beberLiquidos,
      registrarFotosVideos: registrarFotosVideos ?? this.registrarFotosVideos,
      viaParto: viaParto ?? this.viaParto,
      anestesia: anestesia ?? this.anestesia,
      corteVaginal: corteVaginal ?? this.corteVaginal,
      posicaoPreferida: identical(posicaoPreferida, _sentinel)
          ? this.posicaoPreferida
          : posicaoPreferida as String?,
      outraPosicao: identical(outraPosicao, _sentinel)
          ? this.outraPosicao
          : outraPosicao as String?,
      quemCortaCordao: quemCortaCordao ?? this.quemCortaCordao,
      coletaCelulasTronco: coletaCelulasTronco ?? this.coletaCelulasTronco,
      contatoPeleAPele: contatoPeleAPele ?? this.contatoPeleAPele,
      amamentarPrimeiraHora:
          amamentarPrimeiraHora ?? this.amamentarPrimeiraHora,
      restricoesAmamentacao:
          restricoesAmamentacao ?? this.restricoesAmamentacao,
      primeiroBanho: primeiroBanho ?? this.primeiroBanho,
      querAlivioDor: querAlivioDor ?? this.querAlivioDor,
      massagem: massagem ?? this.massagem,
      exerciciosBola: exerciciosBola ?? this.exerciciosBola,
      exerciciosRespiracao: exerciciosRespiracao ?? this.exerciciosRespiracao,
      banhoChuveiro: banhoChuveiro ?? this.banhoChuveiro,
      banhoBanheira: banhoBanheira ?? this.banhoBanheira,
      acupuntura: acupuntura ?? this.acupuntura,
      acupressao: acupressao ?? this.acupressao,
      outroMetodo: outroMetodo ?? this.outroMetodo,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanoPartoModel &&
        other.id == id &&
        other.acompanhante == acompanhante &&
        other.rasparPelosIntimos == rasparPelosIntimos &&
        other.lavagemIntestinal == lavagemIntestinal &&
        other.ambientePoucaLuz == ambientePoucaLuz &&
        other.ouvirMusica == ouvirMusica &&
        other.beberLiquidos == beberLiquidos &&
        other.registrarFotosVideos == registrarFotosVideos &&
        other.viaParto == viaParto &&
        other.anestesia == anestesia &&
        other.corteVaginal == corteVaginal &&
        other.posicaoPreferida == posicaoPreferida &&
        other.outraPosicao == outraPosicao &&
        other.quemCortaCordao == quemCortaCordao &&
        other.coletaCelulasTronco == coletaCelulasTronco &&
        other.contatoPeleAPele == contatoPeleAPele &&
        other.amamentarPrimeiraHora == amamentarPrimeiraHora &&
        other.restricoesAmamentacao == restricoesAmamentacao &&
        other.primeiroBanho == primeiroBanho &&
        other.querAlivioDor == querAlivioDor &&
        other.massagem == massagem &&
        other.exerciciosBola == exerciciosBola &&
        other.exerciciosRespiracao == exerciciosRespiracao &&
        other.banhoChuveiro == banhoChuveiro &&
        other.banhoBanheira == banhoBanheira &&
        other.acupuntura == acupuntura &&
        other.acupressao == acupressao &&
        other.outroMetodo == outroMetodo &&
        other.observacoes == observacoes;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    acompanhante,
    rasparPelosIntimos,
    lavagemIntestinal,
    ambientePoucaLuz,
    ouvirMusica,
    beberLiquidos,
    registrarFotosVideos,
    viaParto,
    anestesia,
    corteVaginal,
    posicaoPreferida,
    outraPosicao,
    quemCortaCordao,
    coletaCelulasTronco,
    contatoPeleAPele,
    amamentarPrimeiraHora,
    restricoesAmamentacao,
    primeiroBanho,
    querAlivioDor,
    massagem,
    exerciciosBola,
    exerciciosRespiracao,
    banhoChuveiro,
    banhoBanheira,
    acupuntura,
    acupressao,
    outroMetodo,
    observacoes,
  ]);
}
