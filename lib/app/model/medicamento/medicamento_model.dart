/// Modelo do domínio MEDICAMENTO (contrato FASE 8G / 9D).
///
/// `id` é UUID gerado pelo backend. `frequencia` é texto livre (o
/// `medicationTime` do Flutter legado — ex.: "6 em 6 horas"), NUNCA um horário
/// de relógio (HH:mm). A escrita ([toWriteJson]) envia apenas `nome`, `dose` e
/// `frequencia` — nunca `id`, `gestacao_id` nem timestamps (o vínculo vem da
/// rota `/gestacoes/{gestacao_id}/medicamentos`).
class MedicamentoModel {
  final String id;
  final String nome;
  final String dose;
  final String frequencia;

  const MedicamentoModel({
    required this.id,
    required this.nome,
    required this.dose,
    required this.frequencia,
  });

  /// Desserialização defensiva: campo obrigatório com tipo inválido anula o
  /// parse (nunca gera objeto aparentemente válido).
  static MedicamentoModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final id = data['id'];
    final nome = data['nome'];
    final dose = data['dose'];
    final frequencia = data['frequencia'];

    if (id is! String ||
        nome is! String ||
        dose is! String ||
        frequencia is! String) {
      return null;
    }

    return MedicamentoModel(
      id: id,
      nome: nome,
      dose: dose,
      frequencia: frequencia,
    );
  }

  /// Payload de escrita (POST/PUT — full update) com as chaves do contrato.
  Map<String, dynamic> toWriteJson() {
    return {
      'nome': nome,
      'dose': dose,
      'frequencia': frequencia,
    };
  }
}
