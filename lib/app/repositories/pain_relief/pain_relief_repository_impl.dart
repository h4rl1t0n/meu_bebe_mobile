import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/pain_relief.dart';
import 'pain_relief_repository.dart';

class PainReliefRepositoryImpl implements PainReliefRepository {
  static final PainReliefRepositoryImpl _instance = PainReliefRepositoryImpl._internal();
  PainReliefRepositoryImpl._internal();
  factory PainReliefRepositoryImpl() => _instance;

  @override
  Future<Result<PainRelief?, Failure>> getPainRelief() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('pain_relief', limit: 1);

      if (maps.isEmpty) {
        return Success(null);
      }

      final painRelief = PainRelief.fromMap(maps.first);
      return Success(painRelief);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar dados de alívio da dor: $error'));
    }
  }

  @override
  Future<Result<PainRelief, Failure>> savePainRelief({required PainRelief painRelief}) async {
    try {
      final db = await DB.instance.database;

      if (painRelief.id == 0) {
        final id = await db.insert('pain_relief', painRelief.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(painRelief.copyWith(id: id));
      } else {
        await db.update('pain_relief', painRelief.toMap(), where: 'id = ?', whereArgs: [painRelief.id]);
        return Success(painRelief);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar dados de alívio da dor: $error'));
    }
  }

  @override
  Future<Result<PainRelief, Failure>> updatePainRelief({required PainRelief painRelief}) async {
    return savePainRelief(painRelief: painRelief);
  }
}
