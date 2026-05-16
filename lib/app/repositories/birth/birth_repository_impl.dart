import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/birth.dart';
import 'birth_repository.dart';

class BirthRepositoryImpl implements BirthRepository {
  static final BirthRepositoryImpl _instance = BirthRepositoryImpl._internal();
  BirthRepositoryImpl._internal();
  factory BirthRepositoryImpl() => _instance;

  @override
  Future<Result<Birth?, Failure>> getBirth() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('birth', limit: 1);

      if (maps.isEmpty) {
        return Success(null);
      }

      final birth = Birth.fromMap(maps.first);
      return Success(birth);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar dados do nascimento: $error'));
    }
  }

  @override
  Future<Result<Birth, Failure>> saveBirth({required Birth birth}) async {
    try {
      final db = await DB.instance.database;

      if (birth.id == 0) {
        final id = await db.insert('birth', birth.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(birth.copyWith(id: id));
      } else {
        await db.update('birth', birth.toMap(), where: 'id = ?', whereArgs: [birth.id]);
        return Success(birth);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar dados do nascimento: $error'));
    }
  }

  @override
  Future<Result<Birth, Failure>> updateBirth({required Birth birth}) async {
    return saveBirth(birth: birth);
  }
}
