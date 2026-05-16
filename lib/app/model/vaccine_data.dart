class VaccineData {
  static const _sentinel = Object();

  final int id;
  final String name;
  final bool used;
  final String? createdAt;

  const VaccineData({
    required this.id,
    required this.name,
    required this.used,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'used': used ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory VaccineData.fromMap(Map<String, dynamic> map) {
    return VaccineData(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      used: (map['used'] ?? 0) == 1,
      createdAt: map['created_at'],
    );
  }

  VaccineData copyWith({
    int? id,
    String? name,
    bool? used,
    Object? createdAt = _sentinel,
  }) {
    return VaccineData(
      id: id ?? this.id,
      name: name ?? this.name,
      used: used ?? this.used,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
    );
  }

  @override
  String toString() {
    return 'VaccineData(id: $id, name: $name, used: $used, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VaccineData &&
        other.id == id &&
        other.name == name &&
        other.used == used &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ used.hashCode ^ createdAt.hashCode;
  }
}
