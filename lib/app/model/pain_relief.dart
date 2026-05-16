import '../core/extensions/enum_extensions.dart';

enum NeedPainRelief { yes, no, dontKnow }

class PainRelief {
  static const _sentinel = Object();

  final int id;
  final NeedPainRelief painRelief;
  final bool massage;
  final bool ballExercises;
  final bool breathRelaxExercises;
  final bool showerBath;
  final bool bathtubBath;
  final bool acupuncture;
  final bool acupressure;
  final bool otherMethod;
  final String? createdAt;

  const PainRelief({
    required this.id,
    required this.painRelief,
    required this.massage,
    required this.ballExercises,
    required this.breathRelaxExercises,
    required this.showerBath,
    required this.bathtubBath,
    required this.acupuncture,
    required this.acupressure,
    required this.otherMethod,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pain_relief': painRelief.index,
      'massage': massage ? 1 : 0,
      'ball_exercises': ballExercises ? 1 : 0,
      'breath_relax_exercises': breathRelaxExercises ? 1 : 0,
      'shower_bath': showerBath ? 1 : 0,
      'bathtub_bath': bathtubBath ? 1 : 0,
      'acupuncture': acupuncture ? 1 : 0,
      'acupressure': acupressure ? 1 : 0,
      'other_method': otherMethod ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory PainRelief.fromMap(Map<String, dynamic> map) {
    return PainRelief(
      id: map['id'] ?? 0,
      painRelief: NeedPainRelief.values.safeGet(map['pain_relief'], NeedPainRelief.no),
      massage: (map['massage'] ?? 0) == 1,
      ballExercises: (map['ball_exercises'] ?? 0) == 1,
      breathRelaxExercises: (map['breath_relax_exercises'] ?? 0) == 1,
      showerBath: (map['shower_bath'] ?? 0) == 1,
      bathtubBath: (map['bathtub_bath'] ?? 0) == 1,
      acupuncture: (map['acupuncture'] ?? 0) == 1,
      acupressure: (map['acupressure'] ?? 0) == 1,
      otherMethod: (map['other_method'] ?? 0) == 1,
      createdAt: map['created_at'],
    );
  }

  PainRelief copyWith({
    int? id,
    NeedPainRelief? painRelief,
    bool? massage,
    bool? ballExercises,
    bool? breathRelaxExercises,
    bool? showerBath,
    bool? bathtubBath,
    bool? acupuncture,
    bool? acupressure,
    bool? otherMethod,
    Object? createdAt = _sentinel,
  }) {
    return PainRelief(
      id: id ?? this.id,
      painRelief: painRelief ?? this.painRelief,
      massage: massage ?? this.massage,
      ballExercises: ballExercises ?? this.ballExercises,
      breathRelaxExercises: breathRelaxExercises ?? this.breathRelaxExercises,
      showerBath: showerBath ?? this.showerBath,
      bathtubBath: bathtubBath ?? this.bathtubBath,
      acupuncture: acupuncture ?? this.acupuncture,
      acupressure: acupressure ?? this.acupressure,
      otherMethod: otherMethod ?? this.otherMethod,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
    );
  }

  @override
  String toString() {
    return 'PainRelief(id: $id, painRelief: $painRelief, massage: $massage, ballExercises: $ballExercises, breathRelaxExercises: $breathRelaxExercises, showerBath: $showerBath, bathtubBath: $bathtubBath, acupuncture: $acupuncture, acupressure: $acupressure, otherMethod: $otherMethod, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PainRelief &&
        other.id == id &&
        other.painRelief == painRelief &&
        other.massage == massage &&
        other.ballExercises == ballExercises &&
        other.breathRelaxExercises == breathRelaxExercises &&
        other.showerBath == showerBath &&
        other.bathtubBath == bathtubBath &&
        other.acupuncture == acupuncture &&
        other.acupressure == acupressure &&
        other.otherMethod == otherMethod &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        painRelief.hashCode ^
        massage.hashCode ^
        ballExercises.hashCode ^
        breathRelaxExercises.hashCode ^
        showerBath.hashCode ^
        bathtubBath.hashCode ^
        acupuncture.hashCode ^
        acupressure.hashCode ^
        otherMethod.hashCode ^
        createdAt.hashCode;
  }
}
