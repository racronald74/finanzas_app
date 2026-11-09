import 'package:flutter/material.dart';

import '../data/models/notification_model.dart';
import '../data/services/notification_service.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

/// Provider encargado de administrar el estado
/// del módulo de Notificaciones.
class NotificationProvider extends ChangeNotifier {
  /// Servicio encargado de la lógica de notificaciones.
  final NotificationService _notificationService = NotificationService();

  /// Repositorio para consultar y actualizar las preferencias del usuario.
  final UserRepository _userRepository = UserRepository();

  /// Preferencias actuales de notificaciones.
  UserModel? _notificationSettings;

  /// Permite consultar las preferencias desde la interfaz.
  UserModel? get notificationSettings => _notificationSettings;

  /// Lista completa de notificaciones.
  List<NotificationModel> _notifications = [];

  /// Indica si existe una operación en ejecución.
  bool _isLoading = false;

  /// Mensaje de error para mostrar en pantalla.
  String _errorMessage = '';

  /// Lectura pública de las notificaciones.
  List<NotificationModel> get notifications => _notifications;

  /// Estado de carga.
  bool get isLoading => _isLoading;

  /// Último mensaje de error.
  String get errorMessage => _errorMessage;

  /// Obtiene las notificaciones pendientes de lectura.
  List<NotificationModel> get unreadNotifications {
    return _notifications.where((notification) => !notification.leida).toList();
  }

  /// Obtiene las notificaciones que ya fueron leídas.
  List<NotificationModel> get readNotifications {
    return _notifications.where((notification) => notification.leida).toList();
  }

  /// Cantidad de notificaciones pendientes de lectura.
  int get unreadCount => unreadNotifications.length;

  /// Carga las preferencias de notificaciones del usuario.
  Future<void> loadNotificationSettings(int idUsuario) async {
    _errorMessage = '';
    notifyListeners();

    try {
      _notificationSettings = await _userRepository.getUserById(idUsuario);
    } catch (e) {
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Actualiza y guarda las preferencias de notificaciones.
  Future<bool> updateNotificationSettings({
    required int idUsuario,
    required bool notificacionesActivas,
    required bool notificacionesMetas,
    required bool notificacionesDeudas,
    required bool notificacionesObligaciones,
  }) async {
    _errorMessage = '';

    try {
      final updatedRows = await _userRepository.updateNotificationPreferences(
        idUsuario: idUsuario,
        notificacionesActivas: notificacionesActivas,
        notificacionesMetas: notificacionesMetas,
        notificacionesDeudas: notificacionesDeudas,
        notificacionesObligaciones: notificacionesObligaciones,
      );

      if (updatedRows == 0) return false;

      // Actualiza las preferencias locales después de guardarlas.
      await loadNotificationSettings(idUsuario);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Carga las notificaciones del usuario.
  Future<void> loadNotifications(int idUsuario) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _notifications = await _notificationService.listarNotificaciones(
        idUsuario,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Genera una nueva notificación.
  Future<bool> createNotification({
    required int idUsuario,
    required String tipo,
    required String mensaje,
    int? idEventoOrigen,
  }) async {
    _errorMessage = '';
    _isLoading = true;
    notifyListeners();

    try {
      final idNotificacion = await _notificationService.generarNotificacion(
        idUsuario: idUsuario,
        tipo: tipo,
        mensaje: mensaje,
        idEventoOrigen: idEventoOrigen,
      );

      // Si devuelve null, no se generó por configuración o duplicidad.
      if (idNotificacion == null) {
        return false;
      }

      await loadNotifications(idUsuario);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marca una notificación como leída.
  Future<bool> markAsRead({
    required int idNotificacion,
    required int idUsuario,
  }) async {
    try {
      await _notificationService.marcarComoLeida(
        idNotificacion: idNotificacion,
        idUsuario: idUsuario,
      );

      await loadNotifications(idUsuario);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Marca todas las notificaciones como leídas.
  Future<bool> markAllAsRead(int idUsuario) async {
    try {
      await _notificationService.marcarTodasComoLeidas(idUsuario);

      await loadNotifications(idUsuario);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Elimina una notificación.
  Future<bool> deleteNotification({
    required int idNotificacion,
    required int idUsuario,
  }) async {
    try {
      await _notificationService.eliminarNotificacion(
        idNotificacion: idNotificacion,
        idUsuario: idUsuario,
      );

      await loadNotifications(idUsuario);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Elimina todas las notificaciones del usuario.
  Future<bool> deleteAllNotifications(int idUsuario) async {
    try {
      await _notificationService.eliminarTodasLasNotificaciones(idUsuario);

      await loadNotifications(idUsuario);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
