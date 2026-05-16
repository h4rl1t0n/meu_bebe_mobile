import '../core/extensions/enum_extensions.dart';

enum WhoCutUmbilicalCord { professional, companion, me, dontKnow }

enum SkinBabyContact { yes, no, dontKnow }

enum BreastfeedFirstHour { yes, no, dontKnow }

enum FirstBath { professional, companion, me, dontKnow }

class Birth {
  static const _sentinel = Object();

  final int id;
  final WhoCutUmbilicalCord whoCut;
  final bool collectStemCells;
  final SkinBabyContact skinBabyContact;
  final BreastfeedFirstHour breastfeedFirstHour;
  final bool breastfeedRestrictions;
  final FirstBath firstBath;
  final String? createdAt;

  const Birth({
    required this.id,
    required this.whoCut,
    required this.collectStemCells,
    required this.skinBabyContact,
    required this.breastfeedFirstHour,
    required this.breastfeedRestrictions,
    required this.firstBath,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'who_cut': whoCut.index,
      'collect_stem_cells': collectStemCells ? 1 : 0,
      'skin_baby_contact': skinBabyContact.index,
      'breastfeed_first_hour': breastfeedFirstHour.index,
      'breastfeed_restrictions': breastfeedRestrictions ? 1 : 0,
      'first_bath': firstBath.index,
      'created_at': createdAt,
    };
  }

  factory Birth.fromMap(Map<String, dynamic> map) {
    return Birth(
      id: map['id'] ?? 0,
      whoCut: WhoCutUmbilicalCord.values.safeGet(map['who_cut'], WhoCutUmbilicalCord.professional),
      collectStemCells: (map['collect_stem_cells'] ?? 0) == 1,
      skinBabyContact: SkinBabyContact.values.safeGet(map['skin_baby_contact'], SkinBabyContact.yes),
      breastfeedFirstHour: BreastfeedFirstHour.values.safeGet(map['breastfeed_first_hour'], BreastfeedFirstHour.yes),
      breastfeedRestrictions: (map['breastfeed_restrictions'] ?? 0) == 1,
      firstBath: FirstBath.values.safeGet(map['first_bath'], FirstBath.professional),
      createdAt: map['created_at'],
    );
  }

  Birth copyWith({
    int? id,
    WhoCutUmbilicalCord? whoCut,
    bool? collectStemCells,
    SkinBabyContact? skinBabyContact,
    BreastfeedFirstHour? breastfeedFirstHour,
    bool? breastfeedRestrictions,
    FirstBath? firstBath,
    Object? createdAt = _sentinel,
  }) {
    return Birth(
      id: id ?? this.id,
      whoCut: whoCut ?? this.whoCut,
      collectStemCells: collectStemCells ?? this.collectStemCells,
      skinBabyContact: skinBabyContact ?? this.skinBabyContact,
      breastfeedFirstHour: breastfeedFirstHour ?? this.breastfeedFirstHour,
      breastfeedRestrictions: breastfeedRestrictions ?? this.breastfeedRestrictions,
      firstBath: firstBath ?? this.firstBath,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
    );
  }

  @override
  String toString() {
    return 'Birth(id: $id, whoCut: $whoCut, collectStemCells: $collectStemCells, skinBabyContact: $skinBabyContact, breastfeedFirstHour: $breastfeedFirstHour, breastfeedRestrictions: $breastfeedRestrictions, firstBath: $firstBath, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Birth &&
        other.id == id &&
        other.whoCut == whoCut &&
        other.collectStemCells == collectStemCells &&
        other.skinBabyContact == skinBabyContact &&
        other.breastfeedFirstHour == breastfeedFirstHour &&
        other.breastfeedRestrictions == breastfeedRestrictions &&
        other.firstBath == firstBath &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        whoCut.hashCode ^
        collectStemCells.hashCode ^
        skinBabyContact.hashCode ^
        breastfeedFirstHour.hashCode ^
        breastfeedRestrictions.hashCode ^
        firstBath.hashCode ^
        createdAt.hashCode;
  }
}
