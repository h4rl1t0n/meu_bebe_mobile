class Exam {
  static const _sentinel = Object();

  final int id;
  final String title;
  final String examDate;
  final String description;
  final String? createdAt;

  const Exam({
    required this.id,
    required this.title,
    required this.examDate,
    required this.description,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'exam_date': examDate,
      'description': description,
      'created_at': createdAt,
    };
  }

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      examDate: map['exam_date'] ?? '',
      description: map['description'] ?? '',
      createdAt: map['created_at'],
    );
  }

  Exam copyWith({
    int? id,
    String? title,
    String? examDate,
    String? description,
    Object? createdAt = _sentinel,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      examDate: examDate ?? this.examDate,
      description: description ?? this.description,
      createdAt: identical(createdAt, _sentinel) ? this.createdAt : createdAt as String?,
    );
  }

  @override
  String toString() {
    return 'Exam(id: $id, title: $title, examDate: $examDate, description: $description, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exam &&
        other.id == id &&
        other.title == title &&
        other.examDate == examDate &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        examDate.hashCode ^
        description.hashCode ^
        createdAt.hashCode;
  }
}
