// Permite notificar cambios a la interfaz
import 'package:flutter/material.dart';

// Servicio de autenticación
import '../data/services/auth_service.dart';

// Modelo usuario
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  // Servicio que contiene las reglas de negocio
  final AuthService _authService = AuthService();

  // Usuario autenticado actualmente
  UserModel? _currentUser;

  // Mensajes de respuesta para mostrar en pantalla
  String _message = '';

  // Indica si se está ejecutando una operación
  bool _isLoading = false;

  // Getters (lectura pública)

  UserModel? get currentUser => _currentUser;

  String get message => _message;

  bool get isLoading => _isLoading;

  /// Registrar usuario
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

  /// Iniciar sesión
  Future<bool> login({
    required String correo,
    required String contrasena,
  }) async {
    _isLoading = true;

    notifyListeners();

    _currentUser = await _authService.login(
      correo: correo,
      contrasena: contrasena,
    );

    _isLoading = false;

    notifyListeners();

    return _currentUser != null;
  }

  /// Cerrar sesión
  void logout() {
    _currentUser = null;

    notifyListeners();
  }

  /// Actualiza datos del usuario autenticado
  Future<bool> updateProfile({
    required String nombre,
    required String correo,
  }) async {
    if (_currentUser == null) return false;

    final success = await _authService.updateUser(
      idUsuario: _currentUser!.idUsuario!,
      nombre: nombre,
      correo: correo,
    );

    if (success) {
      _currentUser = _currentUser!.copyWith(nombre: nombre, correo: correo);

      notifyListeners();
    }

    return success;
  }

  /// Cambia la contraseña del usuario actual
  Future<bool> updatePassword(String nuevaContrasena) async {
    if (_currentUser == null) {
      return false;
    }

    final success = await _authService.updatePassword(
      idUsuario: _currentUser!.idUsuario!,

      nuevaContrasena: nuevaContrasena,
    );

    if (success) {
      _currentUser = _currentUser!.copyWith(contrasena: nuevaContrasena);

      notifyListeners();
    }

    return success;
  }
}
