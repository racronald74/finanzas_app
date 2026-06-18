import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/user_model.dart';

class UserRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<int> insertUser(UserModel user) async {
    final Database db = await _databaseHelper.database;

    return db.insert('usuario', user.toMap());
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'usuario',
      where: 'correo = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return UserModel.fromMap(result.first);
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await _databaseHelper.database;

    return db.update(
      'usuario',
      user,
      where: 'id_usuario = ?',
      whereArgs: [user['id_usuario']],
    );
  }

  Future<int> updatePassword({
    required int idUsuario,
    required String nuevaContrasena,
  }) async {
    final db = await _databaseHelper.database;

    return db.update(
      'usuario',
      {'contrasena': nuevaContrasena},
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }

  Future<int> updatePasswordByEmail({
    required String correo,
    required String nuevaContrasena,
  }) async {
    final db = await _databaseHelper.database;

    return db.update(
      'usuario',
      {'contrasena': nuevaContrasena},
      where: 'correo = ?',
      whereArgs: [correo.trim().toLowerCase()],
    );
  }

  Future<int> updateFixedIncome({
    required int idUsuario,
    required double ingresoFijoMensual,
  }) async {
    final db = await _databaseHelper.database;

    return db.update(
      'usuario',
      {'ingreso_fijo_mensual': ingresoFijoMensual},
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }

  Future<int> updateLastAccess(int idUsuario) async {
    final db = await _databaseHelper.database;

    return db.update(
      'usuario',
      {'ultimo_acceso': DateTime.now().toIso8601String()},
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }
}
