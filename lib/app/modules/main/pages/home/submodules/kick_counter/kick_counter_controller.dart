import 'dart:async';
import 'dart:convert';

import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kick_session_model.dart';

part 'kick_counter_controller.g.dart';

class KickCounterController = KickCounterControllerBase
    with _$KickCounterController;

abstract class KickCounterControllerBase with Store {
  static const String historyStorageKey = 'KICK_COUNTER_HISTORY_V1';

  final Future<SharedPreferences> Function() _prefsProvider;
  Timer? _timer;

  KickCounterControllerBase({Future<SharedPreferences> Function()? prefsProvider})
      : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  @observable
  bool isLoading = false;

  @observable
  int kickCount = 0;

  @observable
  int targetKicks = 10;

  @observable
  int secondsElapsed = 0;

  @observable
  bool isRunning = false;

  @observable
  bool isCompleted = false;

  @observable
  ObservableList<DateTime> kickTimestamps = ObservableList<DateTime>();

  @observable
  ObservableList<KickSessionModel> sessionHistory =
      ObservableList<KickSessionModel>();

  @computed
  String get formattedTime {
    final s = (secondsElapsed % 60).toString().padLeft(2, '0');
    final h = secondsElapsed ~/ 3600;
    final m = ((secondsElapsed % 3600) ~/ 60).toString().padLeft(2, '0');
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:$m:$s';
    }
    return '$m:$s';
  }

  @computed
  double get progress {
    if (targetKicks <= 0) return 1.0;
    final p = kickCount / targetKicks;
    return p > 1.0 ? 1.0 : p;
  }

  /// Alerta clínico baseado na FEBRASGO / Ministério da Saúde:
  /// Se a contagem ultrapassar 2 horas (7200 segundos) sem atingir a meta de 10 movimentos,
  /// recomenda-se orientar a gestante a repousar, alimentar-se e, se persistir, buscar avaliação.
  @computed
  bool get needsClinicalAttention =>
      secondsElapsed >= 7200 && kickCount < targetKicks;

  @action
  Future<void> initialize() async {
    isLoading = true;
    try {
      await loadHistory();
    } finally {
      isLoading = false;
    }
  }

  @action
  void startSession() {
    if (isRunning) return;
    if (isCompleted) {
      resetSession();
    }
    isRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  @action
  void _tick() {
    if (isRunning) {
      secondsElapsed++;
    }
  }

  @action
  void pauseSession() {
    isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  @action
  Future<void> registerKick() async {
    if (isCompleted) return;

    if (!isRunning) {
      startSession();
    }

    kickCount++;
    kickTimestamps.add(DateTime.now());

    if (kickCount >= targetKicks) {
      isCompleted = true;
      pauseSession();
      await saveSession();
    }
  }

  @action
  void undoKick() {
    if (kickCount <= 0) return;
    kickCount--;
    if (kickTimestamps.isNotEmpty) {
      kickTimestamps.removeLast();
    }
    if (isCompleted && kickCount < targetKicks) {
      isCompleted = false;
    }
  }

  @action
  void resetSession() {
    pauseSession();
    secondsElapsed = 0;
    kickCount = 0;
    isCompleted = false;
    kickTimestamps.clear();
  }

  @action
  Future<void> saveSession() async {
    if (kickCount == 0 && secondsElapsed == 0) return;

    final session = KickSessionModel(
      date: DateTime.now(),
      durationSeconds: secondsElapsed,
      kickCount: kickCount,
      targetKicks: targetKicks,
      completed: isCompleted,
      timestamps: kickTimestamps.toList(),
    );

    sessionHistory.insert(0, session);
    await _persistHistory();
  }

  @action
  Future<void> loadHistory() async {
    final prefs = await _prefsProvider();
    final raw = prefs.getString(historyStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((e) => KickSessionModel.fromMap(e as Map<String, dynamic>))
            .toList();
        sessionHistory
          ..clear()
          ..addAll(list);
      } catch (_) {
        // Fallback em caso de dados corrompidos
        sessionHistory.clear();
      }
    }
  }

  @action
  Future<void> clearHistory() async {
    sessionHistory.clear();
    final prefs = await _prefsProvider();
    await prefs.remove(historyStorageKey);
  }

  Future<void> _persistHistory() async {
    final prefs = await _prefsProvider();
    final encoded = jsonEncode(sessionHistory.map((s) => s.toMap()).toList());
    await prefs.setString(historyStorageKey, encoded);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
