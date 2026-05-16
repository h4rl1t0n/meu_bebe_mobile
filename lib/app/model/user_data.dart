class UserData {
  static const _sentinel = Object();

  final int id;
  final String name;
  final String? email;
  final String? phone;

  const UserData({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      email: map['email'],
      phone: map['phone'],
    );
  }

  UserData copyWith({
    int? id,
    String? name,
    Object? email = _sentinel,
    Object? phone = _sentinel,
  }) {
    return UserData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: identical(email, _sentinel) ? this.email : email as String?,
      phone: identical(phone, _sentinel) ? this.phone : phone as String?,
    );
  }

  @override
  String toString() {
    return 'UserData(id: $id, name: $name, email: $email, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserData &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ email.hashCode ^ phone.hashCode;
  }
}
