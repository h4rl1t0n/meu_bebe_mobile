import '../core/extensions/enum_extensions.dart';

enum BirthWay { vaginal, cesarean, dontKnow }

enum Anesthesia { yes, no, dontKnow }

enum VaginalCut { yes, no, dontKnow }

enum Positions {
  lyingDown,
  sitting,
  crouched,
  aside,
  onKnees,
  standing,
  dontKnow,
  otherPosition,
}

class BirthMoment {
  static const _sentinel = Object();

  final int id;
  final BirthWay birthWay;
  final Anesthesia anesthesia;
  final VaginalCut vaginalCut;
  final Positions? preferredPosition;
  final String? otherPosition;
  final String? createdAt;

  const BirthMoment({
    required this.id,
    required this.birthWay,
    required this.anesthesia,
    required this.vaginalCut,
    this.preferredPosition,
    this.otherPosition,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'birth_way': birthWay.index,
      'anesthesia': anesthesia.index,
      'vaginal_cut': vaginalCut.index,
      'preferred_position': preferredPosition?.index,
      'other_position': otherPosition,
      'created_at': createdAt,
    };
  }

  factory BirthMoment.fromMap(Map<String, dynamic> map) {
    return BirthMoment(
      id: map['id'] ?? 0,
      birthWay: BirthWay.values.safeGet(map['birth_way'], BirthWay.vaginal),
      anesthesia: Anesthesia.values.safeGet(map['anesthesia'], Anesthesia.yes),
      vaginalCut: VaginalCut.values.safeGet(map['vaginal_cut'], VaginalCut.yes),
      preferredPosition: map['preferred_position'] != null
          ? Positions.values.safeGet(map['preferred_position'], Positions.lyingDown)
          : null,
      otherPosition: map['other_position'],
      createdAt: map['created_at'],
    );
  }

  BirthMoment copyWith({
    int? id,
    BirthWay? birthWay,
    Anesthesia? anesthesia,
    VaginalCut? vaginalCut,
    Object? preferredPosition = _sentinel,
    Object? otherPosition = _sentinel,
    Object? createdAt = _sentinel,
  }) {
    return BirthMoment(
      id: id ?? this.id,
      birthWay: birthWay ?? this.birthWay,
      anesthesia: anesthesia ?? this.anesthesia,
      vaginalCut: vaginalCut ?? this.vaginalCut,
      preferredPosition: identical(preferredPosition, _sentinel) ? this.preferredPosition : preferredPosition as Positions?,
      otherPosition: identical(otherPosition, _sentinel) ? this.otherPosition : otherPosition as String?,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
    );
  }

  @override
  String toString() {
    return 'BirthMoment(id: $id, birthWay: $birthWay, anesthesia: $anesthesia, vaginalCut: $vaginalCut, preferredPosition: $preferredPosition, otherPosition: $otherPosition, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BirthMoment &&
        other.id == id &&
        other.birthWay == birthWay &&
        other.anesthesia == anesthesia &&
        other.vaginalCut == vaginalCut &&
        other.preferredPosition == preferredPosition &&
        other.otherPosition == otherPosition &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        birthWay.hashCode ^
        anesthesia.hashCode ^
        vaginalCut.hashCode ^
        preferredPosition.hashCode ^
        otherPosition.hashCode ^
        createdAt.hashCode;
  }
}
