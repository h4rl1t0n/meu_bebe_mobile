/// Modelo do domínio VACINA (contrato FASE 8G / 9D).
///
/// `id` é UUID gerado pelo backend (identidade técnica da ocorrência). `nome` é
/// o identificador SEMÂNTICO estável que liga o registro ao item do catálogo
/// visual (ex.: "HB_1", "dTpa") — ver [VacinaCatalogo]. `aplicada` é o booleano
/// "tomada" (o `used` do Flutter legado). A escrita ([toWriteJson]) envia apenas
/// `nome` e `aplicada` — nunca `id`, `gestacao_id` nem timestamps.
class VacinaModel {
  final String id;
  final String nome;
  final bool aplicada;

  const VacinaModel({
    required this.id,
    required this.nome,
    required this.aplicada,
  });

  /// Desserialização defensiva: campo obrigatório com tipo inválido anula o
  /// parse (nunca gera objeto aparentemente válido).
  static VacinaModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final id = data['id'];
    final nome = data['nome'];
    final aplicada = data['aplicada'];

    if (id is! String || nome is! String || aplicada is! bool) {
      return null;
    }

    return VacinaModel(id: id, nome: nome, aplicada: aplicada);
  }

  /// Payload de escrita (POST/PUT — full update) com as chaves do contrato.
  Map<String, dynamic> toWriteJson() {
    return {
      'nome': nome,
      'aplicada': aplicada,
    };
  }

  VacinaModel copyWith({String? id, String? nome, bool? aplicada}) {
    return VacinaModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      aplicada: aplicada ?? this.aplicada,
    );
  }
}
