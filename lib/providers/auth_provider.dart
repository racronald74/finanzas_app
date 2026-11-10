// Permite notificar cambios a la interfaz
import 'package:flutter/material.dart';

// Servicio de autenticación
import '../data/services/auth_service.dart';

// Modelo usuario
import '../data/models/user_model.dart';

// Servicio centralizado de sincronización de recordatorios
import '../data/services/reminder_sync_service.dart';
// Servicio de notificaciones locales de Android.
import '../data/services/local_notification_service.dart';

// Proveedor de autenticación para manejar el estado de autenticación del usuario y las operaciones relacionadas.
class AuthProvider extends ChangeNotifier {
  // Servicio que contiene las reglas de negocio
  final AuthService _authService = AuthService();

  // Usuario autenticado actualmente
  UserModel? _currentUser;

  // Mensajes de respuesta para mostrar en pantalla
  String _message = '';

  // Mensaje correspondiente a la última actualización del perfil.
  String _profileMessage = '';

  String get profileMessage => _profileMessage;

  // Indica si se está ejecutando una operación
  bool _isLoading = false;

  // Getters (lectura pública)

  UserModel? get currentUser => _currentUser;

  String get message => _message;

  bool get isLoading => _isLoading;

  /// Metodo para registrar usuario
  Future<void> registerUser({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    _isLoading = true;

    // Actualiza la interfaz
    notifyListeners();

    _message = await _authService.registerUser(
      nombre: nombre,
      correo: correo,
      contrasena: contrasena,
    );

    _isLoading = false;

    notifyListeners();
  }

  /// Método para iniciar sesión.
  Future<bool> login({
    required String correo,
    required String contrasena,
  }) async {
    _isLoading = true;

    notifyListeners();

    try {
      // Autentica al usuario.
      _currentUser = await _authService.login(
        correo: correo,
        contrasena: contrasena,
      );

      try {
        // Inicializa el servicio de notificaciones locales.
        final localNotificationService = LocalNotificationService();

        // Solicita permiso para mostrar notificaciones.
        final permisoNotificaciones = await localNotificationService
            .requestPermissions();

        debugPrint('PERMISO NOTIFICACIONES: $permisoNotificaciones');

        // Comprueba el permiso para programar alarmas exactas.
        bool permisoExacto = await localNotificationService
            .canScheduleExactAlarms();

        // Solicita el permiso si todavía no está concedido.
        if (!permisoExacto) {
          permisoExacto = await localNotificationService
              .requestExactAlarmPermission();
        }

        debugPrint('PERMISO ALARMAS EXACTAS: $permisoExacto');

        // Sincroniza los recordatorios de las tres categorías.
        final reminderSyncService = ReminderSyncService();

        debugPrint('========== INICIO SINCRONIZACIÓN ==========');

        await reminderSyncService.sincronizarRecordatorios(
          _currentUser!.idUsuario!,
        );

        debugPrint('========== FIN SINCRONIZACIÓN ==========');
      } catch (e) {
        // Evita que un error de notificaciones impida iniciar sesión.
        debugPrint('Error al sincronizar recordatorios: $e');
      }

      return _currentUser != null;
    } finally {
      // Restaura el estado de carga incluso si ocurre un error.
      _isLoading = false;

      notifyListeners();
    }
  }

  /// Metodo para cerrar sesión
  void logout() {
    _currentUser = null;

    notifyListeners();
  }

  /// Actualiza los datos personales del usuario autenticado.
  Future<bool> updateProfile({
    required String nombre,
    required String correo,
  }) async {
    if (_currentUser == null) {
      _profileMessage = 'No hay un usuario autenticado';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Solicita al servicio la actualización de los datos.
      final result = await _authService.updateUser(
        idUsuario: _currentUser!.idUsuario!,
        nombre: nombre,
        correo: correo,
      );

      if (result != null) {
        _profileMessage = result;
        return false;
      }

      // Actualiza el usuario en memoria después de guardar en SQLite.
      _currentUser = _currentUser!.copyWith(
        nombre: nombre.trim(),
        correo: correo.trim().toLowerCase(),
      );

      _profileMessage = 'Datos personales actualizados correctamente';

      return true;
    } catch (e) {
      _profileMessage = 'Ocurrió un error al actualizar los datos';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Metodo para cambiar la contraseña del usuario actual
  Future<bool> updatePassword(String nuevaContrasena) async {
    if (_currentUser == null) {
      return false;
    }

    final success = await _authService.updatePassword(
      idUsuario: _currentUser!.idUsuario!,

      nuevaContrasena: nuevaContrasena,
    );

    if (success) {
      notifyListeners();
    }

    return success;
  }

  Future<void> resetPassword({
    required String correo,
    required String nuevaContrasena,
  }) async {
    _isLoading = true;
    notifyListeners();

    _message = await _authService.resetPassword(
      correo: correo,
      nuevaContrasena: nuevaContrasena,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Metodo para actualizar el ingreso fijo mensual del usuario
  Future<bool> updateFixedIncome(double ingresoFijoMensual) async {
    if (_currentUser == null) {
      return false;
    }

    final success = await _authService.updateFixedIncome(
      idUsuario: _currentUser!.idUsuario!,
      ingresoFijoMensual: ingresoFijoMensual,
    );

    if (success) {
      _currentUser = _currentUser!.copyWith(
        ingresoFijoMensual: ingresoFijoMensual,
      );

      notifyListeners();
    }

    return success;
  }
}
