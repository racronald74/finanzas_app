import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/obligation_model.dart';

/// Repositorio encargado de las operaciones
/// sobre la tabla obligacion.
///
/// Esta clase es la única que accede directamente
/// a SQLite para las obligaciones.
class ObligationRepository {
  /// Instancia del helper de base de datos.
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Inserta una nueva obligación.
  ///
  /// Devuelve el ID generado por SQLite.
  Future<int> insertObligation(ObligationModel obligation) async {
    final Database db = await _databaseHelper.database;

    return await db.insert('obligacion', obligation.toMap());
  }

  /// Obtiene todas las obligaciones de un usuario.
  ///
  /// Las más próximas a vencer aparecen primero.
  Future<List<ObligationModel>> getObligationsByUser(int idUsuario) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      'obligacion',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha_vencimiento ASC',
    );

    return result.map((item) => ObligationModel.fromMap(item)).toList();
  }

  /// Obtiene las obligaciones de un usuario según su estado.
  ///
  /// Estados esperados:
  /// - Pendiente
  /// - Pagada
  Future<List<ObligationModel>> getObligationsByStatus(
    int idUsuario,
    String estado,
  ) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      'obligacion',
      where: 'id_usuario = ? AND estado = ?',
      whereArgs: [idUsuario, estado],
      orderBy: 'fecha_vencimiento ASC',
    );

    return result.map((item) => ObligationModel.fromMap(item)).toList();
  }

  /// Actualiza una obligación existente.
  Future<int> updateObligation(
    ObligationModel obligation, {
    DatabaseExecutor? executor,
  }) async {
    final DatabaseExecutor db = executor ?? await _databaseHelper.database;

    return await db.update(
      'obligacion',
      obligation.toMap(),
      where: 'id_obligacion = ?',
      whereArgs: [obligation.idObligacion],
    );
  }

  /// Elimina una obligación.
  Future<int> deleteObligation(int idObligacion) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'obligacion',
      where: 'id_obligacion = ?',
      whereArgs: [idObligacion],
    );
  }
}
