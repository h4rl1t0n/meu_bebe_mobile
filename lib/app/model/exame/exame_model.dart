/// Modelo do domínio EXAME (contrato FASE 8F / 9C).
///
/// `categoria` é string livre opcional; [ultrassom] é o valor reservado ao
/// mapeamento legado da 1ª ultrassonografia (ver [firstUltrasoundDate]). A
/// escrita envia `titulo`, `data_exame`, `descricao` e `categoria` — nunca
/// `id`, `gestacao_id` nem timestamps.
class ExameModel {
  static const ultrassom = 'ultrassom';

  final String id;
  final String titulo;
  final String dataExame;
  final String descricao;
  final String? categoria;

  const ExameModel({
    required this.id,
    required this.titulo,
    required this.dataExame,
    required this.descricao,
    this.categoria,
  });

  /// Desserialização defensiva: campo obrigatório com tipo inválido anula o
  /// parse; `categoria` é opcional (tipo inválido vira `null`).
  static ExameModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final id = data['id'];
    final titulo = data['titulo'];
    final dataExame = data['data_exame'];
    final descricao = data['descricao'];

    if (id is! String ||
        titulo is! String ||
        dataExame is! String ||
        descricao is! String) {
      return null;
    }

    final categoria = data['categoria'];
    return ExameModel(
      id: id,
      titulo: titulo,
      dataExame: dataExame,
      descricao: descricao,
      categoria: categoria is String ? categoria : null,
    );
  }

  /// Payload de escrita (POST/PUT — full update) com as chaves do contrato.
  Map<String, dynamic> toWriteJson() {
    return {
      'titulo': titulo,
      'data_exame': dataExame,
      'descricao': descricao,
      'categoria': categoria,
    };
  }

  /// Primeira ultrassonografia = data (ISO) mais antiga dentre os exames com
  /// `categoria == [ultrassom]`. Retorna `null` se não houver ultrassom.
  ///
  /// Fonte única de verdade é EXAMES (nunca um campo em GESTAÇÃO).
  static String? firstUltrasoundDate(List<ExameModel> exames) {
    final ultrasounds = exames
        .where((e) => e.categoria == ultrassom)
        .toList();
    if (ultrasounds.isEmpty) return null;
    ultrasounds.sort((a, b) => a.dataExame.compareTo(b.dataExame));
    return ultrasounds.first.dataExame;
  }
}
