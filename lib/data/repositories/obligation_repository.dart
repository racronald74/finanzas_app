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

  /// Obtiene una obligación por su identificador.
  Future<ObligationModel?> getObligationById(int idObligacion) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'obligacion',
      where: 'id_obligacion = ?',
      whereArgs: [idObligacion],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return ObligationModel.fromMap(result.first);
  }

  /// Activa o desactiva una recurrencia.
  Future<void> updateRecurrenceActive({
    required int idObligacion,
    required bool recurrenciaActiva,
  }) async {
    final Database db = await _databaseHelper.database;

    await db.update(
      'obligacion',
      {'recurrencia_activa': recurrenciaActiva ? 1 : 0},
      where: 'id_obligacion = ?',
      whereArgs: [idObligacion],
    );
  }

  /// Asigna el grupo de recurrencia a una obligación.
  Future<void> updateRecurrenceGroup({
    required int idObligacion,
    required int idGrupoRecurrencia,
  }) async {
    final Database db = await _databaseHelper.database;

    await db.update(
      'obligacion',
      {'id_grupo_recurrencia': idGrupoRecurrencia},
      where: 'id_obligacion = ?',
      whereArgs: [idObligacion],
    );
  }

  /// Desactiva toda una serie de obligaciones recurrentes.
  Future<void> deactivateRecurrenceGroup(int idGrupoRecurrencia) async {
    final Database db = await _databaseHelper.database;

    await db.update(
      'obligacion',
      {'recurrencia_activa': 0},
      where: 'id_grupo_recurrencia = ?',
      whereArgs: [idGrupoRecurrencia],
    );
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
      orderBy: '''
  CASE
    WHEN estado = 'Pendiente' THEN 0
    ELSE 1
  END ASC,
  fecha_vencimiento DESC
''',
    );

    return result.map((item) => ObligationModel.fromMap(item)).toList();
  }

  /// Busca una obligación recurrente del usuario
  /// dentro del mismo mes y año.
  ///
  /// Se utiliza para evitar duplicar una obligación
  /// recurrente al materializar un nuevo período.
  Future<ObligationModel?> getRecurringObligationByPeriod({
    required int idUsuario,
    required String nombre,
    required String frecuencia,
    required int year,
    required int month,
  }) async {
    final Database db = await _databaseHelper.database;

    final String fechaInicio = DateTime(year, month, 1).toIso8601String();

    final String fechaFin = DateTime(year, month + 1, 1).toIso8601String();

    final List<Map<String, dynamic>> result = await db.query(
      'obligacion',
      where: '''
      id_usuario = ?
      AND nombre = ?
      AND frecuencia = ?
      AND es_recurrente = 1
      AND fecha_vencimiento >= ?
      AND fecha_vencimiento < ?
    ''',
      whereArgs: [idUsuario, nombre, frecuencia, fechaInicio, fechaFin],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return ObligationModel.fromMap(result.first);
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
      orderBy: '''
  CASE
    WHEN estado = 'Pendiente' THEN 0
    ELSE 1
  END ASC,
  fecha_vencimiento DESC
''',
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
