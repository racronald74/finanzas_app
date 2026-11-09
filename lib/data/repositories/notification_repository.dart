import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/notification_model.dart';

/// Resultado de guardar una notificación sin duplicados.
class NotificationSaveResult {
  final int idNotificacion;
  final List<int> idsDuplicados;

  NotificationSaveResult({
    required this.idNotificacion,
    required this.idsDuplicados,
  });
}

/// Repositorio encargado de las operaciones
/// sobre la tabla notificacion.
class NotificationRepository {
  /// Instancia del helper de base de datos.
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Inserta una nueva notificación.
  ///
  /// Devuelve el ID generado por SQLite.
  Future<int> insertNotification(NotificationModel notification) async {
    final Database db = await _databaseHelper.database;

    return await db.insert('notificacion', notification.toMap());
  }

  /// Obtiene una notificación por su ID y usuario.
  Future<NotificationModel?> getNotificationById({
    required int idNotificacion,
    required int idUsuario,
  }) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'notificacion',
      where: 'id_notificacion = ? AND id_usuario = ?',
      whereArgs: [idNotificacion, idUsuario],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return NotificationModel.fromMap(result.first);
  }

  /// Obtiene todas las notificaciones de un usuario.
  ///
  /// Las más recientes aparecen primero.
  Future<List<NotificationModel>> getNotificationsByUser(int idUsuario) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'notificacion',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha DESC, id_notificacion DESC',
    );

    return result.map((item) => NotificationModel.fromMap(item)).toList();
  }

  /// Obtiene las notificaciones pendientes de lectura.
  Future<List<NotificationModel>> getUnreadNotifications(int idUsuario) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'notificacion',
      where: 'id_usuario = ? AND leida = 0',
      whereArgs: [idUsuario],
      orderBy: 'fecha DESC, id_notificacion DESC',
    );

    return result.map((item) => NotificationModel.fromMap(item)).toList();
  }

  /// Obtiene las notificaciones que ya fueron leídas.
  Future<List<NotificationModel>> getReadNotifications(int idUsuario) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'notificacion',
      where: 'id_usuario = ? AND leida = 1',
      whereArgs: [idUsuario],
      orderBy: 'fecha DESC, id_notificacion DESC',
    );

    return result.map((item) => NotificationModel.fromMap(item)).toList();
  }

  /// Marca una notificación como leída.
  Future<int> markAsRead({
    required int idNotificacion,
    required int idUsuario,
  }) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'notificacion',
      {'leida': 1, 'fecha_lectura': DateTime.now().toIso8601String()},
      where: 'id_notificacion = ? AND id_usuario = ?',
      whereArgs: [idNotificacion, idUsuario],
    );
  }

  /// Marca todas las notificaciones de un usuario como leídas.
  Future<int> markAllAsRead(int idUsuario) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'notificacion',
      {'leida': 1, 'fecha_lectura': DateTime.now().toIso8601String()},
      where: 'id_usuario = ? AND leida = 0',
      whereArgs: [idUsuario],
    );
  }

  /// Elimina una notificación de un usuario.
  Future<int> deleteNotification({
    required int idNotificacion,
    required int idUsuario,
  }) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'notificacion',
      where: 'id_notificacion = ? AND id_usuario = ?',
      whereArgs: [idNotificacion, idUsuario],
    );
  }

  /// Elimina todas las notificaciones de un usuario.
  Future<int> deleteAllNotifications(int idUsuario) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'notificacion',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }

  /// Comprueba si ya existe una notificación para el mismo evento y fecha.
  Future<bool> notificationExists({
    required int idUsuario,
    required String tipo,
    required int idEventoOrigen,
    String? fechaEvento,
  }) async {
    // Obtiene la conexión con la base de datos.
    final Database db = await _databaseHelper.database;

    // Busca una notificación del mismo usuario, tipo, evento y fecha.
    final result = await db.query(
      'notificacion',
      columns: ['id_notificacion'],
      where: '''
        id_usuario = ?
        AND tipo = ?
        AND id_evento_origen = ?
        AND fecha_evento IS ?
      ''',
      whereArgs: [idUsuario, tipo, idEventoOrigen, fechaEvento],
      limit: 1,
    );

    // Devuelve true si ya existe una notificación para ese evento y fecha.
    return result.isNotEmpty;
  }

  /// Actualiza el mensaje de una notificación asociada a un evento.
  Future<int> updateNotificationMessage({
    required int idUsuario,
    required String tipo,
    required int idEventoOrigen,
    required String fechaEvento,
    required String mensaje,
  }) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      'notificacion',
      {'mensaje': mensaje},
      where: '''
        id_usuario = ?
        AND tipo = ?
        AND id_evento_origen = ?
        AND fecha_evento = ?
      ''',
      whereArgs: [idUsuario, tipo, idEventoOrigen, fechaEvento],
    );
  }

  /// Elimina las notificaciones asociadas a una obligación específica.
  Future<int> deleteNotificationsByEvent({
    required int idUsuario,
    required String tipo,
    required int idEventoOrigen,
  }) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'notificacion',
      where: '''
        id_usuario = ?
        AND tipo = ?
        AND id_evento_origen = ?
      ''',
      whereArgs: [idUsuario, tipo, idEventoOrigen],
    );
  }

  /// Obtiene una notificación asociada a un evento específico.
  ///
  /// Permite recuperar su identificador para sincronizar
  /// el registro de SQLite con la notificación local.
  Future<NotificationModel?> getNotificationByEvent({
    required int idUsuario,
    required String tipo,
    required int idEventoOrigen,
    required String fechaEvento,
  }) async {
    // Obtiene la conexión con la base de datos.
    final Database db = await _databaseHelper.database;

    // Busca la notificación correspondiente al evento y su fecha.
    final result = await db.query(
      'notificacion',
      where: '''
        id_usuario = ?
        AND tipo = ?
        AND id_evento_origen = ?
        AND fecha_evento = ?
      ''',
      whereArgs: [idUsuario, tipo, idEventoOrigen, fechaEvento],
      limit: 1,
    );

    // Devuelve null cuando todavía no existe el registro.
    if (result.isEmpty) {
      return null;
    }

    // Convierte el registro encontrado en su modelo.
    return NotificationModel.fromMap(result.first);
  }

  /// Obtiene todas las notificaciones asociadas a un evento.
  ///
  /// Permite recuperar sus identificadores antes de eliminarlas
  /// de SQLite y cancelar también los avisos locales.
  Future<List<NotificationModel>> getNotificationsByEvent({
    required int idUsuario,
    required String tipo,
    required int idEventoOrigen,
  }) async {
    // Obtiene la conexión con la base de datos.
    final Database db = await _databaseHelper.database;

    // Consulta todas las notificaciones del evento indicado.
    final result = await db.query(
      'notificacion',
      where: '''
        id_usuario = ?
        AND tipo = ?
        AND id_evento_origen = ?
      ''',
      whereArgs: [idUsuario, tipo, idEventoOrigen],
    );

    // Convierte los registros encontrados en modelos.
    return result.map((item) => NotificationModel.fromMap(item)).toList();
  }

  /// Inserta o recupera una notificación de forma atómica.
  ///
  /// Si ya existen registros del mismo evento y fecha:
  /// - Conserva el registro más antiguo.
  /// - Actualiza su mensaje.
  /// - Elimina los registros duplicados.
  /// - Devuelve los identificadores que deben cancelarse en Android.
  Future<NotificationSaveResult> guardarNotificacionUnica(
    NotificationModel notification,
  ) async {
    final Database db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // Busca todos los registros del mismo evento y aniversario.
      final existentes = await txn.query(
        'notificacion',
        where: '''
        id_usuario = ?
        AND tipo = ?
        AND id_evento_origen = ?
        AND fecha_evento = ?
      ''',
        whereArgs: [
          notification.idUsuario,
          notification.tipo,
          notification.idEventoOrigen,
          notification.fechaEvento,
        ],
        orderBy: 'id_notificacion ASC',
      );

      // Si no existe, inserta una nueva notificación.
      if (existentes.isEmpty) {
        final id = await txn.insert('notificacion', notification.toMap());

        return NotificationSaveResult(idNotificacion: id, idsDuplicados: []);
      }

      // Conserva el registro más antiguo.
      final int idConservado = existentes.first['id_notificacion'] as int;

      // Actualiza el mensaje sin modificar su estado de lectura.
      await txn.update(
        'notificacion',
        {'mensaje': notification.mensaje},
        where: 'id_notificacion = ?',
        whereArgs: [idConservado],
      );

      // Obtiene los identificadores de los registros duplicados.
      final idsDuplicados = existentes
          .skip(1)
          .map((registro) => registro['id_notificacion'] as int)
          .toList();

      // Elimina los duplicados de SQLite.
      if (idsDuplicados.isNotEmpty) {
        final marcadores = List.filled(idsDuplicados.length, '?').join(',');

        await txn.delete(
          'notificacion',
          where: 'id_notificacion IN ($marcadores)',
          whereArgs: idsDuplicados,
        );
      }

      return NotificationSaveResult(
        idNotificacion: idConservado,
        idsDuplicados: idsDuplicados,
      );
    });
  }

  /// Elimina las notificaciones duplicadas de las metas de un usuario.
  ///
  /// Conserva el registro más antiguo para cada combinación de:
  /// usuario, tipo, evento y fecha del evento.
  ///
  /// Devuelve los IDs eliminados para cancelar sus alarmas en Android.
  Future<List<int>> eliminarDuplicadosMetas(int idUsuario) async {
    final Database db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // Consulta las notificaciones de metas que tienen evento y fecha.
      // El orden permite conservar siempre el registro más antiguo.
      final registros = await txn.query(
        'notificacion',
        where: '''
        id_usuario = ?
        AND tipo = ?
        AND id_evento_origen IS NOT NULL
        AND fecha_evento IS NOT NULL
      ''',
        whereArgs: [idUsuario, 'meta'],
        orderBy: 'id_notificacion ASC',
      );

      // Almacena las combinaciones de eventos ya encontradas.
      final Set<String> eventosProcesados = {};

      // Almacena los identificadores de los registros duplicados.
      final List<int> idsDuplicados = [];

      for (final registro in registros) {
        // Construye una clave única para identificar el evento y su fecha.
        final clave = [
          registro['id_usuario'],
          registro['tipo'],
          registro['id_evento_origen'],
          registro['fecha_evento'],
        ].join('|');

        // Si la combinación ya existe, el registro actual es duplicado.
        if (eventosProcesados.contains(clave)) {
          idsDuplicados.add(registro['id_notificacion'] as int);
        } else {
          // El primer registro encontrado es el más antiguo y se conserva.
          eventosProcesados.add(clave);
        }
      }

      // Elimina de SQLite los registros duplicados encontrados.
      if (idsDuplicados.isNotEmpty) {
        final marcadores = List.filled(idsDuplicados.length, '?').join(',');

        await txn.delete(
          'notificacion',
          where: 'id_notificacion IN ($marcadores)',
          whereArgs: idsDuplicados,
        );
      }

      // Devuelve los IDs para cancelar sus notificaciones locales.
      return idsDuplicados;
    });
  }
}
