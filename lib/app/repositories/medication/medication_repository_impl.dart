import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/medication.dart';
import 'medication_repository.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  static final MedicationRepositoryImpl _instance = MedicationRepositoryImpl._internal();
  MedicationRepositoryImpl._internal();
  factory MedicationRepositoryImpl() => _instance;

  @override
  Future<Result<List<Medication>, Failure>> getMedications() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('medication');

      final medications = maps.map((map) => Medication.fromMap(map)).toList();
      return Success(medications);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar medicamentos: $error'));
    }
  }

  @override
  Future<Result<Medication, Failure>> saveMedication({required Medication medication}) async {
    try {
      final db = await DB.instance.database;

      if (medication.id == 0) {
        // Inserir novo medicamento
        final id = await db.insert('medication', medication.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(medication.copyWith(id: id));
      } else {
        // Atualizar medicamento existente
        await db.update('medication', medication.toMap(), where: 'id = ?', whereArgs: [medication.id]);
        return Success(medication);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar medicamento: $error'));
    }
  }

  @override
  Future<Result<bool, Failure>> deleteMedication({required int id}) async {
    try {
      final db = await DB.instance.database;
      await db.delete('medication', where: 'id = ?', whereArgs: [id]);
      return Success(true);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao deletar medicamento: $error'));
    }
  }
}
