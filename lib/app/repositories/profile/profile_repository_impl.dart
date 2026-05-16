import 'package:multiple_result/multiple_result.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/fp/failure.dart';
import '../../database/database.dart';
import '../../model/user_data.dart';
import 'profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  static final ProfileRepositoryImpl _instance = ProfileRepositoryImpl._internal();
  ProfileRepositoryImpl._internal();
  factory ProfileRepositoryImpl() => _instance;

  @override
  Future<Result<UserData?, Failure>> getUser() async {
    try {
      final db = await DB.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('user', limit: 1);

      if (maps.isEmpty) {
        return Success(null);
      }

      final user = UserData.fromMap(maps.first);
      return Success(user);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao buscar dados do usuário: $error'));
    }
  }

  @override
  Future<Result<UserData, Failure>> saveUser({required UserData user}) async {
    try {
      final db = await DB.instance.database;

      // 1. Verifica se já existe algum usuário cadastrado
      final existing = await db.query('user', where: 'id = ?', whereArgs: [user.id], limit: 1);

      if (user.id == 0) {
        if (existing.isNotEmpty) {
          // Já existe usuário -> atualizar o existente
          final existingUser = UserData.fromMap(existing.first);

          final updatedUser = user.copyWith(id: existingUser.id);

          await db.update(
            'user',
            updatedUser.toMap(),
            where: 'id = ?',
            whereArgs: [existingUser.id],
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          return Success(updatedUser);
        } else {
          // Não existe -> criar novo
          final id = await db.insert('user', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

          return Success(user.copyWith(id: id));
        }
      }

      // 2. Se user.id != 0, tentamos atualizar
      final affected = await db.update(
        'user',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (affected == 0) {
        // Não existia -> criar novo
        final id = await db.insert('user', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        return Success(user.copyWith(id: id));
      }

      // Atualização deu certo
      return Success(user);
    } catch (error) {
      return Error(CustomMessageError.getMessage('Erro ao salvar dados do usuário: $error'));
    }
  }

  @override
  Future<Result<UserData, Failure>> updateUser({required UserData user}) async {
    return saveUser(user: user);
  }
}
