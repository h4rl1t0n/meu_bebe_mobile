class Appointment {
  static const _sentinel = Object();

  final int id;
  final String title;
  final String appointmentDate;
  final String description;
  final String? createdAt;

  const Appointment({
    required this.id,
    required this.title,
    required this.appointmentDate,
    required this.description,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'appointment_date': appointmentDate,
      'description': description,
      'created_at': createdAt,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      appointmentDate: map['appointment_date'] ?? '',
      description: map['description'] ?? '',
      createdAt: map['created_at'],
    );
  }

  Appointment copyWith({
    int? id,
    String? title,
    String? appointmentDate,
    String? description,
    Object? createdAt = _sentinel,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      description: description ?? this.description,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
    );
  }

  @override
  String toString() {
    return 'Appointment(id: $id, title: $title, appointmentDate: $appointmentDate, description: $description, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Appointment &&
        other.id == id &&
        other.title == title &&
        other.appointmentDate == appointmentDate &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        appointmentDate.hashCode ^
        description.hashCode ^
        createdAt.hashCode;
  }
}
