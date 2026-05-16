import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/exam.dart';
import 'exams_repository.dart';

class ExamsRepositoryImpl implements ExamsRepository {
  static final ExamsRepositoryImpl _instance = ExamsRepositoryImpl._internal();
  ExamsRepositoryImpl._internal();
  factory ExamsRepositoryImpl() => _instance;

  @override
  Future<Result<List<Exam>, Failure>> getExams() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('exam');
      final exams = maps.map((map) => Exam.fromMap(map)).toList();
      return Success(exams);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar exames: $error'));
    }
  }

  @override
  Future<Result<Exam, Failure>> saveExam({required Exam exam}) async {
    try {
      final db = await DB.instance.database;

      if (exam.id == 0) {
        // Inserir novo exame
        final id = await db.insert('exam', exam.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(exam.copyWith(id: id));
      } else {
        // Atualizar exame existente
        await db.update('exam', exam.toMap(), where: 'id = ?', whereArgs: [exam.id]);
        return Success(exam);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar exame: $error'));
    }
  }

  @override
  Future<Result<bool, Failure>> deleteExam({required int id}) async {
    try {
      final db = await DB.instance.database;

      await db.delete('exam', where: 'id = ?', whereArgs: [id]);

      return Success(true);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao deletar exame: $error'));
    }
  }
}
