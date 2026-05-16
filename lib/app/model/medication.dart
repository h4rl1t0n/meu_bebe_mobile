class Medication {
  static const _sentinel = Object();

  final int id;
  final String name;
  final String dose;
  final String medicationTime;
  final String? createdAt;

  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.medicationTime,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'medication_time': medicationTime,
      'created_at': createdAt,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      dose: map['dose'] ?? '',
      medicationTime: map['medication_time'] ?? '',
      createdAt: map['created_at'],
    );
  }

  Medication copyWith({
    int? id,
    String? name,
    String? dose,
    String? medicationTime,
    Object? createdAt = _sentinel,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      medicationTime: medicationTime ?? this.medicationTime,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
    );
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dose: $dose, medicationTime: $medicationTime, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medication &&
        other.id == id &&
        other.name == name &&
        other.dose == dose &&
        other.medicationTime == medicationTime &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        dose.hashCode ^
        medicationTime.hashCode ^
        createdAt.hashCode;
  }
}
