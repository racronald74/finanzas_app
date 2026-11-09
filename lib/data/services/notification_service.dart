import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/user_repository.dart';
import 'local_notification_service.dart';

import 'package:flutter/foundation.dart'; // Permite utilizar debugPrint para el diagnóstico.

/// Servicio encargado de gestionar la lógica de negocio
/// relacionada con las notificaciones.
class NotificationService {
  // Repositorios necesarios para administrar las notificaciones y usuarios.
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  final UserRepository _userRepository = UserRepository();

  // Servicio encargado de mostrar las notificaciones en el dispositivo.
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();

  /// Valida si el usuario tiene habilitadas las notificaciones.
  Future<bool> validarConfiguracionNotificaciones(
    int idUsuario, {
    String? tipo,
  }) async {
    // Consulta la configuración actual del usuario.
    final user = await _userRepository.getUserById(idUsuario);

    // Si el usuario no existe, no se permiten notificaciones.
    if (user == null) return false;

    // La preferencia general funciona como interruptor maestro.
    if (!user.notificacionesActivas) return false;

    // Si no se especifica categoría, solo se valida la preferencia general.
    if (tipo == null) return true;

    // Comprueba la preferencia correspondiente a cada categoría.
    switch (tipo.toLowerCase()) {
      case 'meta':
        return user.notificacionesMetas;
      case 'deuda':
        return user.notificacionesDeudas;
      case 'obligacion':
        return user.notificacionesObligaciones;
      default:
        return true;
    }
  }

  /// Genera y almacena una notificación si está permitida.
  ///
  /// Evita duplicados mediante una operación atómica en SQLite.
  /// Si existe un registro anterior, conserva su identificador.
  Future<int?> generarNotificacion({
    required int idUsuario,
    required String tipo,
    required String mensaje,
    int? idEventoOrigen,
    String? fechaEvento,
    DateTime? fechaProgramada,
    bool mostrarEnAndroid = true,
  }) async {
    // Comprueba las preferencias del usuario.
    final notificacionesActivas = await validarConfiguracionNotificaciones(
      idUsuario,
      tipo: tipo,
    );

    if (!notificacionesActivas) return null;

    // Construye el modelo de la notificación.
    final notification = NotificationModel(
      tipo: tipo,
      mensaje: mensaje,
      fecha: DateTime.now().toIso8601String(),
      leida: false,
      idUsuario: idUsuario,
      idEventoOrigen: idEventoOrigen,
      fechaEvento: fechaEvento,
    );

    int idNotificacion;

    // Utiliza el guardado atómico cuando existe un evento y su fecha.
    if (idEventoOrigen != null && fechaEvento != null) {
      final resultado = await _notificationRepository.guardarNotificacionUnica(
        notification,
      );

      // Conserva el identificador del registro único.
      idNotificacion = resultado.idNotificacion;

      // Cancela las alarmas locales de los registros duplicados.
      for (final int idDuplicado in resultado.idsDuplicados) {
        await _localNotificationService.cancelNotification(idDuplicado);
      }
    } else {
      // Para notificaciones sin evento asociado utiliza la inserción normal.
      idNotificacion = await _notificationRepository.insertNotification(
        notification,
      );
    }

    if (idNotificacion <= 0) return null;

    // Programa la notificación en Android solamente si está permitido.
    if (mostrarEnAndroid) {
      debugPrint('NOTIFICACIONES: iniciando programación local.');

      await _sincronizarNotificacionLocal(
        idNotificacion: idNotificacion,
        tipo: tipo,
        mensaje: mensaje,
        fechaProgramada: fechaProgramada,
      );

      debugPrint('NOTIFICACIONES: finalizó programación local.');
    }

    return idNotificacion;
  }

  /// Elimina duplicados de las notificaciones de metas de un usuario.
  ///
  /// Conserva el registro más antiguo en SQLite y cancela
  /// las alarmas locales correspondientes a los registros eliminados.
  Future<int> limpiarDuplicadosMetas(int idUsuario) async {
    // Elimina los registros duplicados de las metas en SQLite.
    final idsDuplicados = await _notificationRepository.eliminarDuplicadosMetas(
      idUsuario,
    );

    // Cancela en Android las alarmas de los registros eliminados.
    for (final int idDuplicado in idsDuplicados) {
      await _localNotificationService.cancelNotification(idDuplicado);
    }

    // Devuelve la cantidad de registros duplicados eliminados.
    return idsDuplicados.length;
  }

  /// Actualiza el mensaje y sincroniza la notificación local.
  Future<int> actualizarMensajeNotificacion({
    required int idUsuario,
    required String tipo,
    required int idEventoOrigen,
    required String fechaEvento,
    required String mensaje,
    DateTime? fechaProgramada,
  }) async {
    // Recupera el registro existente para conservar su identificador.
    final notification = await _notificationRepository.getNotificationByEvent(
      idUsuario: idUsuario,
      tipo: tipo,
      idEventoOrigen: idEventoOrigen,
      fechaEvento: fechaEvento,
    );

    if (notification == null || notification.idNotificacion == null) {
      return 0;
    }

    // Actualiza el mensaje almacenado en SQLite.
    final resultado = await _notificationRepository.updateNotificationMessage(
      idUsuario: idUsuario,
      tipo: tipo,
      idEventoOrigen: idEventoOrigen,
      fechaEvento: fechaEvento,
      mensaje: mensaje,
    );

    if (resultado > 0) {
      // Actualiza también el aviso local utilizando el mismo identificador.
      await _sincronizarNotificacionLocal(
        idNotificacion: notification.idNotificacion!,
        tipo: tipo,
        mensaje: mensaje,
        fechaProgramada:
            fechaProgramada ?? _obtenerFechaProgramada(tipo, fechaEvento),
      );
    }

    return resultado;
  }

  /// Calcula la fecha del recordatorio a partir de la fecha del evento.
  DateTime? _obtenerFechaProgramada(String tipo, String fechaEvento) {
    // Convierte la fecha del evento en una fecha sin hora.
    final fecha = DateTime.tryParse(fechaEvento);
    if (fecha == null) return null;

    final fechaNormalizada = DateTime(fecha.year, fecha.month, fecha.day);

    // Metas y obligaciones se notifican un día antes del evento.
    if (tipo.toLowerCase() == 'meta' || tipo.toLowerCase() == 'obligacion') {
      return fechaNormalizada.subtract(const Duration(days: 1));
    }

    // Las deudas se notifican el mismo día del aniversario.
    return fechaNormalizada;
  }

  /// Programa o muestra una notificación local.
  Future<void> _sincronizarNotificacionLocal({
    required int idNotificacion,
    required String tipo,
    required String mensaje,
    DateTime? fechaProgramada,
  }) async {
    // Si no hay fecha futura, cancela el aviso anterior.
    if (fechaProgramada == null) {
      await _localNotificationService.cancelNotification(idNotificacion);
      return;
    }

    // Establece la hora acordada: 9:00 a. m.
    final fechaConHora = DateTime(
      fechaProgramada.year,
      fechaProgramada.month,
      fechaProgramada.day,
      9,
    );

    // Si la fecha ya pasó, cancela el aviso pendiente.
    if (fechaConHora.isBefore(DateTime.now())) {
      await _localNotificationService.cancelNotification(idNotificacion);
      return;
    }

    // Programa el aviso local con el mismo identificador de SQLite.
    await _localNotificationService.scheduleNotification(
      id: idNotificacion,
      title: _obtenerTitulo(tipo),
      body: mensaje,
      scheduledDate: fechaConHora,
      payload: idNotificacion.toString(),
    );

    // Consulta temporalmente las alarmas pendientes en Android.
    await _localNotificationService.diagnosticarNotificacionesPendientes();
  }

  /// Programa un recordatorio de deuda sin crear un registro en SQLite.
  ///
  /// Utiliza un identificador negativo basado en el ID de la deuda
  /// para evitar colisiones con los identificadores de SQLite.
  Future<bool> programarRecordatorioDeuda({
    required int idUsuario,
    required int idDeuda,
    required String mensaje,
    required DateTime fechaProgramada,
  }) async {
    // Comprueba que el usuario tenga habilitados los recordatorios de deudas.
    final notificacionesActivas = await validarConfiguracionNotificaciones(
      idUsuario,
      tipo: 'deuda',
    );

    if (!notificacionesActivas) return false;

    // Establece la hora acordada para los recordatorios.
    final fechaConHora = DateTime(
      fechaProgramada.year,
      fechaProgramada.month,
      fechaProgramada.day,
      9,
    );

    // No programa fechas que ya hayan pasado.
    if (!fechaConHora.isAfter(DateTime.now())) return false;

    // Utiliza un ID negativo para diferenciarlo de los registros SQLite.
    final idNotificacionLocal = -idDeuda;

    // Programa directamente la notificación en Android.
    await _localNotificationService.scheduleNotification(
      id: idNotificacionLocal,
      title: _obtenerTitulo('deuda'),
      body: mensaje,
      scheduledDate: fechaConHora,
      payload: 'deuda:$idDeuda',
    );

    return true;
  }

  /// Cancela el recordatorio local asociado a una deuda.
  Future<void> cancelarRecordatorioDeuda(int idDeuda) async {
    // Utiliza el mismo identificador empleado al programar la alarma.
    await _localNotificationService.cancelNotification(-idDeuda);
  }

  /// Programa un recordatorio de meta sin crear un registro en SQLite.
  ///
  /// Utiliza identificadores negativos reservados para Metas,
  /// independientes de los identificadores utilizados por Deudas.
  Future<bool> programarRecordatorioMeta({
    required int idUsuario,
    required int idMeta,
    required String mensaje,
    required DateTime fechaProgramada,
  }) async {
    // Comprueba que el usuario tenga habilitados los recordatorios de metas.
    final notificacionesActivas = await validarConfiguracionNotificaciones(
      idUsuario,
      tipo: 'meta',
    );

    if (!notificacionesActivas) return false;

    // Establece la hora del recordatorio: 9:00 a. m.
    final fechaConHora = DateTime(
      fechaProgramada.year,
      fechaProgramada.month,
      fechaProgramada.day,
      9,
    );

    // Evita programar fechas que ya hayan pasado.
    if (!fechaConHora.isAfter(DateTime.now())) return false;

    // Reserva un rango de identificadores independiente de Deudas.
    final idNotificacionLocal = -1000000 - idMeta;

    // Programa directamente la alarma en Android sin insertar en SQLite.
    await _localNotificationService.scheduleNotification(
      id: idNotificacionLocal,
      title: _obtenerTitulo('meta'),
      body: mensaje,
      scheduledDate: fechaConHora,
      payload: 'meta:$idMeta',
    );

    return true;
  }

  /// Cancela el recordatorio local asociado a una meta.
  Future<void> cancelarRecordatorioMeta(int idMeta) async {
    // Utiliza el mismo identificador empleado al programar la alarma.
    await _localNotificationService.cancelNotification(-1000000 - idMeta);
  }

  /// Programa un recordatorio de obligación sin crear un registro en SQLite.
  ///
  /// Utiliza un rango de identificadores independiente de metas y deudas.
  Future<bool> programarRecordatorioObligacion({
    required int idUsuario,
    required int idObligacion,
    required String mensaje,
    required DateTime fechaProgramada,
  }) async {
    // Comprueba que el usuario tenga habilitados los recordatorios.
    final notificacionesActivas = await validarConfiguracionNotificaciones(
      idUsuario,
      tipo: 'obligacion',
    );

    if (!notificacionesActivas) return false;

    // Programa el recordatorio a las 9:00 a. m.
    final fechaConHora = DateTime(
      fechaProgramada.year,
      fechaProgramada.month,
      fechaProgramada.day,
      9,
    );

    // No programa fechas que ya hayan pasado.
    if (!fechaConHora.isAfter(DateTime.now())) return false;

    // Reserva un identificador independiente de metas y deudas.
    final idNotificacionLocal = -2000000 - idObligacion;

    // Programa la alarma directamente en Android.
    await _localNotificationService.scheduleNotification(
      id: idNotificacionLocal,
      title: _obtenerTitulo('obligacion'),
      body: mensaje,
      scheduledDate: fechaConHora,
      payload: 'obligacion:$idObligacion',
    );

    return true;
  }

  /// Cancela el recordatorio local asociado a una obligación.
  Future<void> cancelarRecordatorioObligacion(int idObligacion) async {
    // Utiliza el mismo identificador empleado al programar la alarma.
    await _localNotificationService.cancelNotification(-2000000 - idObligacion);
  }

  /// Obtiene el título según el tipo de notificación.
  String _obtenerTitulo(String tipo) {
    // Reutiliza los mismos títulos que el callback de alarmas.
    return LocalNotificationService.obtenerTitulo(tipo);
  }

  /// Obtiene todas las notificaciones de un usuario.
  Future<List<NotificationModel>> listarNotificaciones(int idUsuario) async {
    return _notificationRepository.getNotificationsByUser(idUsuario);
  }

  /// Obtiene las notificaciones pendientes de lectura.
  Future<List<NotificationModel>> listarNotificacionesNoLeidas(
    int idUsuario,
  ) async {
    return _notificationRepository.getUnreadNotifications(idUsuario);
  }

  /// Obtiene las notificaciones que ya fueron leídas.
  Future<List<NotificationModel>> listarNotificacionesLeidas(
    int idUsuario,
  ) async {
    return _notificationRepository.getReadNotifications(idUsuario);
  }

  /// Obtiene una notificación específica.
  Future<NotificationModel?> obtenerNotificacionPorId({
    required int idNotificacion,
    required int idUsuario,
  }) async {
    return _notificationRepository.getNotificationById(
      idNotificacion: idNotificacion,
      idUsuario: idUsuario,
    );
  }

  /// Marca una notificación como leída.
  Future<int> marcarComoLeida({
    required int idNotificacion,
    required int idUsuario,
  }) async {
    return _notificationRepository.markAsRead(
      idNotificacion: idNotificacion,
      idUsuario: idUsuario,
    );
  }

  /// Marca todas las notificaciones del usuario como leídas.
  Future<int> marcarTodasComoLeidas(int idUsuario) async {
    return _notificationRepository.markAllAsRead(idUsuario);
  }

  /// Elimina una notificación específica.
  Future<int> eliminarNotificacion({
    required int idNotificacion,
    required int idUsuario,
  }) async {
    // Cancela el aviso local correspondiente.
    await _localNotificationService.cancelNotification(idNotificacion);

    // Elimina el registro almacenado en SQLite.
    return _notificationRepository.deleteNotification(
      idNotificacion: idNotificacion,
      idUsuario: idUsuario,
    );
  }

  /// Elimina todas las notificaciones de un usuario.
  Future<int> eliminarTodasLasNotificaciones(int idUsuario) async {
    // Recupera los registros del usuario antes de eliminarlos.
    final notificaciones = await _notificationRepository.getNotificationsByUser(
      idUsuario,
    );

    // Cancela únicamente los avisos locales de este usuario.
    for (final notification in notificaciones) {
      if (notification.idNotificacion != null) {
        await _localNotificationService.cancelNotification(
          notification.idNotificacion!,
        );
      }
    }

    // Elimina los registros almacenados en SQLite.
    return _notificationRepository.deleteAllNotifications(idUsuario);
  }

  /// Elimina las notificaciones asociadas a un evento específico.
  Future<int> eliminarNotificacionesPorEvento({
    required int idUsuario,
    required String tipo,
    required int idEventoOrigen,
  }) async {
    // Recupera las notificaciones antes de eliminarlas.
    final notificaciones = await _notificationRepository
        .getNotificationsByEvent(
          idUsuario: idUsuario,
          tipo: tipo,
          idEventoOrigen: idEventoOrigen,
        );

    // Cancela los avisos locales asociados al evento.
    for (final notification in notificaciones) {
      if (notification.idNotificacion != null) {
        await _localNotificationService.cancelNotification(
          notification.idNotificacion!,
        );
      }
    }

    // Elimina los registros de SQLite.
    return _notificationRepository.deleteNotificationsByEvent(
      idUsuario: idUsuario,
      tipo: tipo,
      idEventoOrigen: idEventoOrigen,
    );
  }
}
