import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/appointment.dart';
import 'appointments_repository.dart';

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  static final AppointmentsRepositoryImpl _instance = AppointmentsRepositoryImpl._internal();
  AppointmentsRepositoryImpl._internal();
  factory AppointmentsRepositoryImpl() => _instance;

  @override
  Future<Result<List<Appointment>, Failure>> getAppointments() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('appointment');

      final appointments = maps.map((map) => Appointment.fromMap(map)).toList();
      return Success(appointments);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar consultas: $error'));
    }
  }

  @override
  Future<Result<Appointment, Failure>> saveAppointment({required Appointment appointment}) async {
    try {
      final db = await DB.instance.database;

      if (appointment.id == 0) {
        // Inserir nova consulta
        final id = await db.insert('appointment', appointment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(appointment.copyWith(id: id));
      } else {
        // Atualizar consulta existente
        await db.update('appointment', appointment.toMap(), where: 'id = ?', whereArgs: [appointment.id]);
        return Success(appointment);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar consulta: $error'));
    }
  }

  @override
  Future<Result<bool, Failure>> deleteAppointment({required int id}) async {
    try {
      final db = await DB.instance.database;
      await db.delete('appointment', where: 'id = ?', whereArgs: [id]);
      return Success(true);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao deletar consulta: $error'));
    }
  }
}
