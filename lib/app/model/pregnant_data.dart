class PregnantData {
  static const _sentinel = Object();

  final int id;
  final String name;
  final String? birthDate;
  final String? cpf;
  final String? socialName;
  final String? nationalHealthCard;
  final String? prenatalPlace;
  final String? professionalName;
  final String? prenatalPlaceContact;

  const PregnantData({
    required this.id,
    required this.name,
    this.birthDate,
    this.cpf,
    this.socialName,
    this.nationalHealthCard,
    this.prenatalPlace,
    this.professionalName,
    this.prenatalPlaceContact,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate,
      'cpf': cpf,
      'social_name': socialName,
      'national_health_card': nationalHealthCard,
      'prenatal_place': prenatalPlace,
      'professional_name': professionalName,
      'prenatal_place_contact': prenatalPlaceContact,
    };
  }

  factory PregnantData.fromMap(Map<String, dynamic> map) {
    return PregnantData(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      birthDate: map['birth_date'],
      cpf: map['cpf'],
      socialName: map['social_name'],
      nationalHealthCard: map['national_health_card'],
      prenatalPlace: map['prenatal_place'],
      professionalName: map['professional_name'],
      prenatalPlaceContact: map['prenatal_place_contact'],
    );
  }

  PregnantData copyWith({
    int? id,
    String? name,
    Object? birthDate = _sentinel,
    Object? cpf = _sentinel,
    Object? socialName = _sentinel,
    Object? nationalHealthCard = _sentinel,
    Object? prenatalPlace = _sentinel,
    Object? professionalName = _sentinel,
    Object? prenatalPlaceContact = _sentinel,
  }) {
    return PregnantData(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: identical(birthDate, _sentinel) ? this.birthDate : birthDate as String?,
      cpf: identical(cpf, _sentinel) ? this.cpf : cpf as String?,
      socialName: identical(socialName, _sentinel) ? this.socialName : socialName as String?,
      nationalHealthCard: identical(nationalHealthCard, _sentinel) ? this.nationalHealthCard : nationalHealthCard as String?,
      prenatalPlace: identical(prenatalPlace, _sentinel) ? this.prenatalPlace : prenatalPlace as String?,
      professionalName: identical(professionalName, _sentinel) ? this.professionalName : professionalName as String?,
      prenatalPlaceContact: identical(prenatalPlaceContact, _sentinel) ? this.prenatalPlaceContact : prenatalPlaceContact as String?,
    );
  }

  @override
  String toString() {
    return 'PregnantData(id: $id, name: $name, birthDate: $birthDate, cpf: $cpf, socialName: $socialName, nationalHealthCard: $nationalHealthCard, prenatalPlace: $prenatalPlace, professionalName: $professionalName, prenatalPlaceContact: $prenatalPlaceContact)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PregnantData &&
        other.id == id &&
        other.name == name &&
        other.birthDate == birthDate &&
        other.cpf == cpf &&
        other.socialName == socialName &&
        other.nationalHealthCard == nationalHealthCard &&
        other.prenatalPlace == prenatalPlace &&
        other.professionalName == professionalName &&
        other.prenatalPlaceContact == prenatalPlaceContact;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        birthDate.hashCode ^
        cpf.hashCode ^
        socialName.hashCode ^
        nationalHealthCard.hashCode ^
        prenatalPlace.hashCode ^
        professionalName.hashCode ^
        prenatalPlaceContact.hashCode;
  }
}
