// Importa el modelo Usuario
import '../models/user_model.dart';

// Importa el repositorio
import '../repositories/user_repository.dart';

class AuthService {
  // Instancia del repositorio
  final UserRepository _userRepository = UserRepository();

  /// Registrar nuevo usuario
  Future<String> registerUser({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    // Verifica si ya existe un usuario con ese correo
    final existingUser = await _userRepository.getUserByEmail(correo);

    if (existingUser != null) {
      return 'El correo ya está registrado';
    }

    // Crear objeto usuario
    final user = UserModel(
      nombre: nombre,
      correo: correo,
      contrasena: contrasena,
      fechaRegistro: DateTime.now().toIso8601String(),
    );

    // Guardar usuario
    await _userRepository.insertUser(user);

    return 'Usuario registrado correctamente';
  }

  /// Inicio de sesión
  Future<UserModel?> login({
    required String correo,
    required String contrasena,
  }) async {
    return await _userRepository.login(correo, contrasena);
  }

  /// Actualiza información del usuario
  Future<bool> updateUser({
    required int idUsuario,
    required String nombre,
    required String correo,
  }) async {
    final result = await _userRepository.updateUser({
      'id_usuario': idUsuario,
      'nombre': nombre,
      'correo': correo,
    });

    return result > 0;
  }

  /// Actualiza la contraseña del usuario
  Future<bool> updatePassword({
    required int idUsuario,
    required String nuevaContrasena,
  }) async {
    final result = await _userRepository.updatePassword(
      idUsuario: idUsuario,
      nuevaContrasena: nuevaContrasena,
    );

    return result > 0;
  }
}
