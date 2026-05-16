class PreviousPregnancy {
  static const _sentinel = Object();

  final int id;
  final int? pregnancyNumber;
  final int? givenBirthNumber;
  final int? abortionsNumber;
  final String? createdAt;

  const PreviousPregnancy({
    required this.id,
    this.pregnancyNumber,
    this.givenBirthNumber,
    this.abortionsNumber,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pregnancy_number': pregnancyNumber,
      'given_birth_number': givenBirthNumber,
      'abortions_number': abortionsNumber,
      'created_at': createdAt,
    };
  }

  factory PreviousPregnancy.fromMap(Map<String, dynamic> map) {
    return PreviousPregnancy(
      id: map['id'] ?? 0,
      pregnancyNumber: map['pregnancy_number'],
      givenBirthNumber: map['given_birth_number'],
      abortionsNumber: map['abortions_number'],
      createdAt: map['created_at'],
    );
  }

  PreviousPregnancy copyWith({
    int? id,
    Object? pregnancyNumber = _sentinel,
    Object? givenBirthNumber = _sentinel,
    Object? abortionsNumber = _sentinel,
    Object? createdAt = _sentinel,
  }) {
    return PreviousPregnancy(
      id: id ?? this.id,
      pregnancyNumber: identical(pregnancyNumber, _sentinel) ? this.pregnancyNumber : pregnancyNumber as int?,
      givenBirthNumber: identical(givenBirthNumber, _sentinel) ? this.givenBirthNumber : givenBirthNumber as int?,
      abortionsNumber: identical(abortionsNumber, _sentinel) ? this.abortionsNumber : abortionsNumber as int?,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
    );
  }

  @override
  String toString() {
    return 'PreviousPregnancy(id: $id, pregnancyNumber: $pregnancyNumber, givenBirthNumber: $givenBirthNumber, abortionsNumber: $abortionsNumber, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PreviousPregnancy &&
        other.id == id &&
        other.pregnancyNumber == pregnancyNumber &&
        other.givenBirthNumber == givenBirthNumber &&
        other.abortionsNumber == abortionsNumber &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        pregnancyNumber.hashCode ^
        givenBirthNumber.hashCode ^
        abortionsNumber.hashCode ^
        createdAt.hashCode;
  }
}
