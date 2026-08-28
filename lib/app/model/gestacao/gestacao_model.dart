/// Modelo do domínio GESTAÇÃO ATUAL (contrato congelado FASE 8D).
///
/// Apenas leitura nesta fase: o Perfil exibe a gestação ativa existente. As
/// datas (`data_ultima_menstruacao`, `ended_at`) são mantidas como `String?`
/// para não acoplar a desserialização a um formato específico.
class GestacaoModel {
  final String id;
  final String? dataUltimaMenstruacao;
  final String? localPreNatal;
  final String? profissionalPreNatal;
  final String? contatoLocalPreNatal;
  final String? endedAt;

  const GestacaoModel({
    required this.id,
    this.dataUltimaMenstruacao,
    this.localPreNatal,
    this.profissionalPreNatal,
    this.contatoLocalPreNatal,
    this.endedAt,
  });

  static GestacaoModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final id = data['id'];
    if (id is! String) return null;

    return GestacaoModel(
      id: id,
      dataUltimaMenstruacao: data['data_ultima_menstruacao'] as String?,
      localPreNatal: data['local_pre_natal'] as String?,
      profissionalPreNatal: data['profissional_pre_natal'] as String?,
      contatoLocalPreNatal: data['contato_local_pre_natal'] as String?,
      endedAt: data['ended_at'] as String?,
    );
  }
}
