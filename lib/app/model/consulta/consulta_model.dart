/// Modelo do domínio CONSULTA (contrato FASE 8F / 9C).
///
/// `id` é UUID gerado pelo backend. `dataConsulta` trafega como ISO
/// (`AAAA-MM-DD`). A escrita ([toWriteJson]) envia apenas `titulo`,
/// `data_consulta` e `descricao` — nunca `id`, `gestacao_id` nem timestamps (o
/// vínculo vem da rota `/gestacoes/{gestacao_id}/consultas`).
class ConsultaModel {
  final String id;
  final String titulo;
  final String dataConsulta;
  final String descricao;

  const ConsultaModel({
    required this.id,
    required this.titulo,
    required this.dataConsulta,
    required this.descricao,
  });

  /// Desserialização defensiva: qualquer campo obrigatório com tipo inválido
  /// anula o parse (nunca estoura em runtime).
  static ConsultaModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final id = data['id'];
    final titulo = data['titulo'];
    final dataConsulta = data['data_consulta'];
    final descricao = data['descricao'];

    if (id is! String ||
        titulo is! String ||
        dataConsulta is! String ||
        descricao is! String) {
      return null;
    }

    return ConsultaModel(
      id: id,
      titulo: titulo,
      dataConsulta: dataConsulta,
      descricao: descricao,
    );
  }

  /// Payload de escrita (POST/PUT — full update) com as chaves do contrato.
  Map<String, dynamic> toWriteJson() {
    return {
      'titulo': titulo,
      'data_consulta': dataConsulta,
      'descricao': descricao,
    };
  }
}
