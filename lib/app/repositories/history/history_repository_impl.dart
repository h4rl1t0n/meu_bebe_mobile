import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/previous_pregnancy.dart';
import 'history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  static final HistoryRepositoryImpl _instance = HistoryRepositoryImpl._internal();
  HistoryRepositoryImpl._internal();
  factory HistoryRepositoryImpl() => _instance;

  @override
  Future<Result<PreviousPregnancy?, Failure>> getHistory() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('previous_pregnancy', limit: 1);

      if (maps.isEmpty) {
        return Success(null);
      }

      final history = PreviousPregnancy.fromMap(maps.first);
      return Success(history);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar histórico de gestações: $error'));
    }
  }

  @override
  Future<Result<PreviousPregnancy, Failure>> saveHistory({required PreviousPregnancy history}) async {
    try {
      final db = await DB.instance.database;

      if (history.id == 0) {
        // Inserir novo histórico
        final id = await db.insert('previous_pregnancy', history.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(history.copyWith(id: id));
      } else {
        // Atualizar histórico existente
        await db.update('previous_pregnancy', history.toMap(), where: 'id = ?', whereArgs: [history.id]);
        return Success(history);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar histórico de gestações: $error'));
    }
  }

  @override
  Future<Result<PreviousPregnancy, Failure>> updateHistory({required PreviousPregnancy history}) async {
    return saveHistory(history: history);
  }
}
