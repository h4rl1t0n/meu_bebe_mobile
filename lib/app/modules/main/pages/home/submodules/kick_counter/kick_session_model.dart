import 'dart:convert';

/// Representa o registro de uma sessão do Contador de Movimentos Fetais (Chutes).
///
/// Baseado na recomendação clínica do método Cardiff ("Count-to-Ten"),
/// preconizado pelo Ministério da Saúde e FEBRASGO para vigilância do bem-estar fetal.
class KickSessionModel {
  final DateTime date;
  final int durationSeconds;
  final int kickCount;
  final int targetKicks;
  final bool completed;
  final List<DateTime> timestamps;

  const KickSessionModel({
    required this.date,
    required this.durationSeconds,
    required this.kickCount,
    this.targetKicks = 10,
    required this.completed,
    this.timestamps = const [],
  });

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'durationSeconds': durationSeconds,
    'kickCount': kickCount,
    'targetKicks': targetKicks,
    'completed': completed,
    'timestamps': timestamps.map((t) => t.toIso8601String()).toList(),
  };

  factory KickSessionModel.fromMap(Map<String, dynamic> map) {
    return KickSessionModel(
      date: DateTime.parse(map['date'] as String),
      durationSeconds: (map['durationSeconds'] as num).toInt(),
      kickCount: (map['kickCount'] as num).toInt(),
      targetKicks: (map['targetKicks'] as num?)?.toInt() ?? 10,
      completed: map['completed'] as bool? ?? true,
      timestamps: (map['timestamps'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          const [],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory KickSessionModel.fromJson(String source) =>
      KickSessionModel.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Retorna o tempo formatado em MM:SS ou HH:MM:SS
  String get formattedDuration {
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    final h = durationSeconds ~/ 3600;
    final m = ((durationSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }
}
