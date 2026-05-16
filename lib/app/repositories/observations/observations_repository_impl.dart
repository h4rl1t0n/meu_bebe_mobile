import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/observations.dart';
import 'observations_repository.dart';

class ObservationsRepositoryImpl implements ObservationsRepository {
  static final ObservationsRepositoryImpl _instance = ObservationsRepositoryImpl._internal();
  ObservationsRepositoryImpl._internal();
  factory ObservationsRepositoryImpl() => _instance;

  @override
  Future<Result<Observations?, Failure>> getObservations() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('observations', limit: 1);

      if (maps.isEmpty) {
        return Success(null);
      }

      final observations = Observations.fromMap(maps.first);
      return Success(observations);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar observações: $error'));
    }
  }

  @override
  Future<Result<Observations, Failure>> saveObservations({required Observations observations}) async {
    try {
      final db = await DB.instance.database;

      if (observations.id == 0) {
        final id = await db.insert('observations', observations.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(observations.copyWith(id: id));
      } else {
        await db.update('observations', observations.toMap(), where: 'id = ?', whereArgs: [observations.id]);
        return Success(observations);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar observações: $error'));
    }
  }

  @override
  Future<Result<Observations, Failure>> updateObservations({required Observations observations}) async {
    return saveObservations(observations: observations);
  }
}
