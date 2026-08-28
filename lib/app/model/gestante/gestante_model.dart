/// Modelo do domínio GESTANTE (contrato congelado FASE 8D).
///
/// A escrita (`toWriteJson`) envia apenas os campos aceitos pelo backend
/// (`nome`, `nome_social`, `data_nascimento`, `cpf`, `cns`) — nunca `id`,
/// `user_id` nem timestamps. `data_nascimento` trafega como `YYYY-MM-DD`.
class GestanteModel {
  final String id;
  final String nome;
  final String? nomeSocial;
  final String? dataNascimento;
  final String? cpf;
  final String? cns;

  const GestanteModel({
    required this.id,
    required this.nome,
    this.nomeSocial,
    this.dataNascimento,
    this.cpf,
    this.cns,
  });

  static GestanteModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final id = data['id'];
    final nome = data['nome'];
    if (id is! String || nome is! String) return null;

    return GestanteModel(
      id: id,
      nome: nome,
      nomeSocial: data['nome_social'] as String?,
      dataNascimento: data['data_nascimento'] as String?,
      cpf: data['cpf'] as String?,
      cns: data['cns'] as String?,
    );
  }

  /// Payload de escrita (POST/PUT — full update) com as chaves do contrato.
  Map<String, dynamic> toWriteJson() {
    return {
      'nome': nome,
      'nome_social': nomeSocial,
      'data_nascimento': dataNascimento,
      'cpf': cpf,
      'cns': cns,
    };
  }
}
