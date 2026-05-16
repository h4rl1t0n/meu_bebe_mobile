import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/pregnant_data.dart';
import 'gestation_repository.dart';

class GestationRepositoryImpl implements GestationRepository {
  static final GestationRepositoryImpl _instance = GestationRepositoryImpl._internal();
  GestationRepositoryImpl._internal();
  factory GestationRepositoryImpl() => _instance;

  @override
  Future<Result<PregnantData?, Failure>> getPregnant() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('pregnant', limit: 1);

      if (maps.isEmpty) {
        return Success(null);
      }

      final pregnant = PregnantData.fromMap(maps.first);
      return Success(pregnant);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar dados da gestante: $error'));
    }
  }

  @override
  Future<Result<PregnantData, Failure>> savePregnant({required PregnantData pregnant}) async {
    try {
      final db = await DB.instance.database;

      if (pregnant.id == 0) {
        // Inserir nova gestante
        final id = await db.insert('pregnant', pregnant.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(pregnant.copyWith(id: id));
      } else {
        // Atualizar gestante existente
        await db.update('pregnant', pregnant.toMap(), where: 'id = ?', whereArgs: [pregnant.id]);
        return Success(pregnant);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar dados da gestante: $error'));
    }
  }

  @override
  Future<Result<PregnantData, Failure>> updatePregnant({required PregnantData pregnant}) async {
    return savePregnant(pregnant: pregnant);
  }
}
