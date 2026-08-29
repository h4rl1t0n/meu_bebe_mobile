/// Modelo do domínio AVALIAÇÃO DSS OPERACIONAL (contrato FASE 8I / 9F).
///
/// É o snapshot HISTÓRICO e imutável das respostas do questionário DSS,
/// vinculado à gestação autenticada (append-only). A resposta do backend
/// expõe `id`, `schema_version`, `respostas` (as 6 dimensões / 48 variáveis)
/// e `created_at` — e NÃO expõe `gestacao_id` (o vínculo é derivado da rota,
/// validada por ownership).
///
/// Este recurso é puramente OPERACIONAL: NÃO carrega qualquer saída do modelo
/// experimental. Aqui não há `probability`, `risk`, `score`, classe, threshold,
/// recomendação, IV-DSS, cluster nem `descontinuou_pre_natal` (target). A
/// estimativa continua sendo o `POST /risk-estimate` (stateless).
class AvaliacaoDssModel {
  final String id;
  final String schemaVersion;
  final Map<String, dynamic> respostas;
  final String createdAt;

  const AvaliacaoDssModel({
    required this.id,
    required this.schemaVersion,
    required this.respostas,
    required this.createdAt,
  });

  /// Desserialização defensiva: qualquer campo obrigatório com tipo inválido
  /// anula o parse (nunca estoura em runtime).
  static AvaliacaoDssModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final id = data['id'];
    final schemaVersion = data['schema_version'];
    final respostas = data['respostas'];
    final createdAt = data['created_at'];

    if (id is! String ||
        schemaVersion is! String ||
        respostas is! Map ||
        createdAt is! String) {
      return null;
    }

    return AvaliacaoDssModel(
      id: id,
      schemaVersion: schemaVersion,
      respostas: Map<String, dynamic>.from(respostas),
      createdAt: createdAt,
    );
  }
}
