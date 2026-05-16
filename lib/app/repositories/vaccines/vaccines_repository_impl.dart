import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/vaccine_data.dart';
import 'vaccines_repository.dart';

class VaccinesRepositoryImpl implements VaccinesRepository {
  static final VaccinesRepositoryImpl _instance = VaccinesRepositoryImpl._internal();
  VaccinesRepositoryImpl._internal();
  factory VaccinesRepositoryImpl() => _instance;

  @override
  Future<Result<List<VaccineData>, Failure>> getVaccines() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('vaccine');

      final vaccines = maps.map((map) => VaccineData.fromMap(map)).toList();
      return Success(vaccines);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar vacinas: $error'));
    }
  }

  @override
  Future<Result<VaccineData, Failure>> saveVaccine({required VaccineData vaccine}) async {
    try {
      final db = await DB.instance.database;

      if (vaccine.id == 0) {
        // Inserir nova vacina
        final id = await db.insert('vaccine', vaccine.toMap());
        return Success(vaccine.copyWith(id: id));
      } else {
        // Atualizar vacina existente
        await db.update(
          'vaccine',
          vaccine.toMap(),
          where: 'id = ?',
          whereArgs: [vaccine.id],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return Success(vaccine);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar vacina: $error'));
    }
  }

  @override
  Future<Result<bool, Failure>> deleteVaccine({required int id}) async {
    try {
      final db = await DB.instance.database;

      await db.delete('vaccine', where: 'id = ?', whereArgs: [id]);

      return Success(true);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao deletar vacina: $error'));
    }
  }
}
