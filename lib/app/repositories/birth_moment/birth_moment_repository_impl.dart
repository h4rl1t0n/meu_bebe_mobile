import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/birth_moment.dart';
import 'birth_moment_repository.dart';

class BirthMomentRepositoryImpl implements BirthMomentRepository {
  static final BirthMomentRepositoryImpl _instance = BirthMomentRepositoryImpl._internal();
  BirthMomentRepositoryImpl._internal();
  factory BirthMomentRepositoryImpl() => _instance;

  @override
  Future<Result<BirthMoment?, Failure>> getBirthMoment() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('birth_moment', limit: 1);

      if (maps.isEmpty) {
        return Success(null);
      }

      final birthMoment = BirthMoment.fromMap(maps.first);
      return Success(birthMoment);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar dados do momento do parto: $error'));
    }
  }

  @override
  Future<Result<BirthMoment, Failure>> saveBirthMoment({required BirthMoment birthMoment}) async {
    try {
      final db = await DB.instance.database;

      if (birthMoment.id == 0) {
        final id = await db.insert('birth_moment', birthMoment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(birthMoment.copyWith(id: id));
      } else {
        await db.update('birth_moment', birthMoment.toMap(), where: 'id = ?', whereArgs: [birthMoment.id]);
        return Success(birthMoment);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar dados do momento do parto: $error'));
    }
  }

  @override
  Future<Result<BirthMoment, Failure>> updateBirthMoment({required BirthMoment birthMoment}) async {
    return saveBirthMoment(birthMoment: birthMoment);
  }
}
