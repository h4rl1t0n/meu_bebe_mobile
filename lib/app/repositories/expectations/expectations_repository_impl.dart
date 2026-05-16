import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/expectation.dart';
import 'expectations_repository.dart';

class ExpectationsRepositoryImpl implements ExpectationsRepository {
  static final ExpectationsRepositoryImpl _instance = ExpectationsRepositoryImpl._internal();
  ExpectationsRepositoryImpl._internal();
  factory ExpectationsRepositoryImpl() => _instance;

  @override
  Future<Result<Expectation?, Failure>> getExpectations() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('expectation', limit: 1);

      if (maps.isEmpty) {
        return Success(null);
      }

      final expectation = Expectation.fromMap(maps.first);
      return Success(expectation);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar expectativas: $error'));
    }
  }

  @override
  Future<Result<Expectation, Failure>> saveExpectations({required Expectation expectation}) async {
    try {
      final db = await DB.instance.database;

      if (expectation.id == 0) {
        // Inserir nova expectativa
        final id = await db.insert('expectation', expectation.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(expectation.copyWith(id: id));
      } else {
        // Atualizar expectativa existente
        await db.update('expectation', expectation.toMap(), where: 'id = ?', whereArgs: [expectation.id]);
        return Success(expectation);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar expectativas: $error'));
    }
  }

  @override
  Future<Result<Expectation, Failure>> updateExpectations({required Expectation expectation}) async {
    return saveExpectations(expectation: expectation);
  }
}
