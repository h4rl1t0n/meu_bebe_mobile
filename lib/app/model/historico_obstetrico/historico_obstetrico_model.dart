/// Modelo do domínio HISTÓRICO OBSTÉTRICO (contrato FASE 9B).
///
/// 1:1 com a gestante. Os três contadores são opcionais (>= 0 no backend). O
/// `id` é gerado pelo backend (UUID) e NUNCA é enviado no payload de escrita
/// (ver [toWriteJson]).
class HistoricoObstetricoModel {
  final String id;
  final int? pregnancyNumber;
  final int? givenBirthNumber;
  final int? abortionsNumber;

  const HistoricoObstetricoModel({
    required this.id,
    this.pregnancyNumber,
    this.givenBirthNumber,
    this.abortionsNumber,
  });

  /// Desserialização defensiva: o `id` inválido anula o parse; contadores
  /// opcionais com tipo incorreto viram `null` (nunca estoura em runtime).
  static HistoricoObstetricoModel? tryParse(Object? data) {
    if (data is! Map) return null;

    final id = data['id'];
    if (id is! String) return null;

    final pregnancyNumber = data['pregnancy_number'];
    final givenBirthNumber = data['given_birth_number'];
    final abortionsNumber = data['abortions_number'];

    return HistoricoObstetricoModel(
      id: id,
      pregnancyNumber: pregnancyNumber is int ? pregnancyNumber : null,
      givenBirthNumber: givenBirthNumber is int ? givenBirthNumber : null,
      abortionsNumber: abortionsNumber is int ? abortionsNumber : null,
    );
  }

  /// Payload de escrita (PUT upsert). Sem `id`/timestamps: a API não os aceita.
  Map<String, dynamic> toWriteJson() {
    return {
      'pregnancy_number': pregnancyNumber,
      'given_birth_number': givenBirthNumber,
      'abortions_number': abortionsNumber,
    };
  }
}
