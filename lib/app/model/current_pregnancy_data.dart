class CurrentPregnancyData {
  static const _sentinel = Object();

  final int id;
  final String? lastMenstrualPeriod;
  final String? firstUltrasound;
  final String? createdAt;

  const CurrentPregnancyData({
    required this.id,
    this.lastMenstrualPeriod,
    this.firstUltrasound,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'last_menstrual_period': lastMenstrualPeriod,
      'first_ultrasound': firstUltrasound,
      'created_at': createdAt,
    };
  }

  factory CurrentPregnancyData.fromMap(Map<String, dynamic> map) {
    return CurrentPregnancyData(
      id: map['id'] ?? 0,
      lastMenstrualPeriod: map['last_menstrual_period'],
      firstUltrasound: map['first_ultrasound'],
      createdAt: map['created_at'],
    );
  }

  CurrentPregnancyData copyWith({
    int? id,
    Object? lastMenstrualPeriod = _sentinel,
    Object? firstUltrasound = _sentinel,
    Object? createdAt = _sentinel,
  }) {
    return CurrentPregnancyData(
      id: id ?? this.id,
      lastMenstrualPeriod: identical(lastMenstrualPeriod, _sentinel) ? this.lastMenstrualPeriod : lastMenstrualPeriod as String?,
      firstUltrasound: identical(firstUltrasound, _sentinel) ? this.firstUltrasound : firstUltrasound as String?,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
    );
  }

  @override
  String toString() {
    return 'CurrentPregnancyData(id: $id, lastMenstrualPeriod: $lastMenstrualPeriod, firstUltrasound: $firstUltrasound, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrentPregnancyData &&
        other.id == id &&
        other.lastMenstrualPeriod == lastMenstrualPeriod &&
        other.firstUltrasound == firstUltrasound &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        lastMenstrualPeriod.hashCode ^
        firstUltrasound.hashCode ^
        createdAt.hashCode;
  }
}
