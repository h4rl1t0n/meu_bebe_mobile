import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/current_pregnancy_data.dart';
import 'current_gestation_repository.dart';

class CurrentGestationRepositoryImpl implements CurrentGestationRepository {
  static final CurrentGestationRepositoryImpl _instance = CurrentGestationRepositoryImpl._internal();
  CurrentGestationRepositoryImpl._internal();
  factory CurrentGestationRepositoryImpl() => _instance;

  @override
  Future<Result<CurrentPregnancyData?, Failure>> getGestation() async {
    try {
      final db = await DB.instance.database;
      final result = await db.query('current_pregnancy', limit: 1);

      if (result.isEmpty) {
        return Success(null);
      }

      final gestation = CurrentPregnancyData.fromMap(result.first);
      return Success(gestation);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar dados da gestação atual: $error'));
    }
  }

  @override
  Future<Result<CurrentPregnancyData, Failure>> saveGestation({required CurrentPregnancyData gestation}) async {
    try {
      final db = await DB.instance.database;

      if (gestation.id == 0) {
        // Inserir nova gestação
        final id = await db.insert(
          'current_pregnancy',
          gestation.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return Success(gestation.copyWith(id: id));
      } else {
        // Atualizar gestação existente
        await db.update('current_pregnancy', gestation.toMap(), where: 'id = ?', whereArgs: [gestation.id]);
        return Success(gestation);
      }
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar dados da gestação atual: $error'));
    }
  }

  @override
  Future<Result<CurrentPregnancyData, Failure>> updateGestation({required CurrentPregnancyData gestation}) async {
    return saveGestation(gestation: gestation);
  }
}
