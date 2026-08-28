import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meu_bebe/app/core/fp/backend_failure.dart';
import 'package:meu_bebe/app/model/historico_obstetrico/historico_obstetrico_model.dart';
import 'package:meu_bebe/app/modules/main/pages/childbirth/submodules/history/history_controller.dart';
import 'package:meu_bebe/app/repositories/historico_obstetrico/historico_obstetrico_repository.dart';
import 'package:multiple_result/multiple_result.dart';

const _historico = HistoricoObstetricoModel(
  id: 'hist-1',
  pregnancyNumber: 2,
  givenBirthNumber: 1,
  abortionsNumber: 0,
);

class _FakeHistoricoRepository implements HistoricoObstetricoRepository {
  _FakeHistoricoRepository({this.onGet, this.onSave});

  Future<Result<HistoricoObstetricoModel?, BackendFailure>> Function()? onGet;
  Future<Result<HistoricoObstetricoModel, BackendFailure>> Function(
    HistoricoObstetricoModel,
  )? onSave;
  int saveCalls = 0;

  @override
  Future<Result<HistoricoObstetricoModel?, BackendFailure>> getHistorico() =>
      onGet!();

  @override
  Future<Result<HistoricoObstetricoModel, BackendFailure>> saveHistorico(
    HistoricoObstetricoModel historico,
  ) {
    saveCalls++;
    return onSave!(historico);
  }
}

Result<HistoricoObstetricoModel?, BackendFailure> _getResult(
  HistoricoObstetricoModel? h,
) => Success<HistoricoObstetricoModel?, BackendFailure>(h);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryController.initialize', () {
    test('com histórico → model preenchido e loading false', () async {
      final repo = _FakeHistoricoRepository(
        onGet: () async => _getResult(_historico),
      );
      final c = HistoryController(repo);

      await c.initialize();

      expect(c.model, isNotNull);
      expect(c.model!.id, 'hist-1');
      expect(c.model!.pregnancyNumber, 2);
      expect(c.loading, isFalse);
    });

    test('404 → null (ainda não preenchido), tela abre normal', () async {
      final repo = _FakeHistoricoRepository(
        onGet: () async => _getResult(null),
      );
      final c = HistoryController(repo);

      await c.initialize();

      expect(c.model, isNull);
      expect(c.loading, isFalse);
    });

    test('erro → null, tela abre normal', () async {
      final repo = _FakeHistoricoRepository(
        onGet: () async => const Error(SessionExpiredFailure()),
      );
      final c = HistoryController(repo);

      await c.initialize();

      expect(c.model, isNull);
      expect(c.loading, isFalse);
    });
  });

  group('HistoryController.save', () {
    test('sucesso → retorna true e atualiza model', () async {
      final repo = _FakeHistoricoRepository(
        onGet: () async => _getResult(null),
        onSave: (h) async => Success(h),
      );
      final c = HistoryController(repo);
      await c.initialize();

      final ok = await c.save(_historico);

      expect(ok, isTrue);
      expect(repo.saveCalls, 1);
      expect(c.model!.id, 'hist-1');
    });

    test('erro → retorna false e não atualiza model', () async {
      final repo = _FakeHistoricoRepository(
        onGet: () async => _getResult(null),
        onSave: (h) async => const Error(ValidationFailure()),
      );
      final c = HistoryController(repo);
      await c.initialize();

      final ok = await c.save(_historico);

      expect(ok, isFalse);
      expect(c.model, isNull);
      expect(c.loading, isFalse);
    });

    test('duplo submit → uma única escrita', () async {
      final completer = Completer<Result<HistoricoObstetricoModel, BackendFailure>>();
      final repo = _FakeHistoricoRepository(
        onGet: () async => _getResult(null),
        onSave: (h) => completer.future,
      );
      final c = HistoryController(repo);
      await c.initialize();

      final first = c.save(_historico);
      final second = c.save(_historico);

      completer.complete(Success(_historico));
      final results = await Future.wait([first, second]);

      expect(repo.saveCalls, 1);
      expect(c.model, isNotNull);
      expect(results, [true, false]);
    });
  });
}
