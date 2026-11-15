import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/modules/main/pages/home/submodules/kick_counter/kick_counter_controller.dart';
import 'package:meu_bebe/app/modules/main/pages/home/submodules/kick_counter/kick_session_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KickSessionModel', () {
    test('serializa e desserializa corretamente', () {
      final now = DateTime(2026, 11, 15, 10, 30);
      final session = KickSessionModel(
        date: now,
        durationSeconds: 150,
        kickCount: 10,
        targetKicks: 10,
        completed: true,
        timestamps: [now],
      );

      final map = session.toMap();
      final restored = KickSessionModel.fromMap(map);

      expect(restored.date, now);
      expect(restored.durationSeconds, 150);
      expect(restored.kickCount, 10);
      expect(restored.completed, isTrue);
      expect(restored.timestamps.length, 1);
      expect(restored.formattedDuration, '02:30');
    });

    test('formata duração com horas', () {
      final session = KickSessionModel(
        date: DateTime.now(),
        durationSeconds: 3665, // 1h 1m 5s
        kickCount: 5,
        completed: false,
      );

      expect(session.formattedDuration, '01:01:05');
    });
  });

  group('KickCounterController', () {
    late KickCounterController controller;

    setUp(() {
      controller = KickCounterController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('estado inicial correto', () {
      expect(controller.kickCount, 0);
      expect(controller.targetKicks, 10);
      expect(controller.secondsElapsed, 0);
      expect(controller.isRunning, isFalse);
      expect(controller.isCompleted, isFalse);
      expect(controller.formattedTime, '00:00');
      expect(controller.progress, 0.0);
      expect(controller.needsClinicalAttention, isFalse);
      expect(controller.sessionHistory, isEmpty);
    });

    test('registerKick inicia sessão se não estiver rodando', () async {
      await controller.registerKick();

      expect(controller.kickCount, 1);
      expect(controller.isRunning, isTrue);
      expect(controller.kickTimestamps.length, 1);
      expect(controller.progress, 0.1);
    });

    test('undoKick decrementa contador e remove timestamp', () async {
      await controller.registerKick();
      await controller.registerKick();
      expect(controller.kickCount, 2);
      expect(controller.kickTimestamps.length, 2);

      controller.undoKick();
      expect(controller.kickCount, 1);
      expect(controller.kickTimestamps.length, 1);

      controller.undoKick();
      expect(controller.kickCount, 0);
      expect(controller.kickTimestamps, isEmpty);

      // Não fica negativo
      controller.undoKick();
      expect(controller.kickCount, 0);
    });

    test('ao atingir 10 chutes completa a sessão e salva no histórico', () async {
      for (int i = 0; i < 10; i++) {
        await controller.registerKick();
      }

      expect(controller.kickCount, 10);
      expect(controller.isCompleted, isTrue);
      expect(controller.isRunning, isFalse);
      expect(controller.progress, 1.0);
      expect(controller.sessionHistory.length, 1);
      expect(controller.sessionHistory.first.completed, isTrue);
      expect(controller.sessionHistory.first.kickCount, 10);
    });

    test('pauseSession e startSession controlam o estado isRunning', () {
      controller.startSession();
      expect(controller.isRunning, isTrue);

      controller.pauseSession();
      expect(controller.isRunning, isFalse);
    });

    test('resetSession reseta contagem, cronômetro e timestamps', () async {
      await controller.registerKick();
      await controller.registerKick();
      controller.resetSession();

      expect(controller.kickCount, 0);
      expect(controller.secondsElapsed, 0);
      expect(controller.isRunning, isFalse);
      expect(controller.isCompleted, isFalse);
      expect(controller.kickTimestamps, isEmpty);
    });

    test('needsClinicalAttention dispara após 2 horas com menos de 10 chutes', () {
      expect(controller.needsClinicalAttention, isFalse);

      // Simula passagem de mais de 7200 segundos
      controller.secondsElapsed = 7201;
      controller.kickCount = 5;

      expect(controller.needsClinicalAttention, isTrue);

      // Se atingir 10 chutes, não precisa de atenção
      controller.kickCount = 10;
      expect(controller.needsClinicalAttention, isFalse);
    });

    test('clearHistory limpa o histórico local e persistência', () async {
      for (int i = 0; i < 10; i++) {
        await controller.registerKick();
      }
      expect(controller.sessionHistory.isNotEmpty, isTrue);

      await controller.clearHistory();
      expect(controller.sessionHistory, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(KickCounterControllerBase.historyStorageKey), isNull);
    });

    test('loadHistory restaura histórico do SharedPreferences', () async {
      // Grava uma sessão prévia
      for (int i = 0; i < 10; i++) {
        await controller.registerKick();
      }

      final newController = KickCounterController();
      await newController.initialize();

      expect(newController.sessionHistory.length, 1);
      expect(newController.sessionHistory.first.kickCount, 10);
      newController.dispose();
    });
  });
}
