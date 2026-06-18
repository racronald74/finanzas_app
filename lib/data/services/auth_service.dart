import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'password_hasher.dart';

class AuthService {
  final UserRepository _userRepository = UserRepository();

  Future<String> registerUser({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final normalizedName = nombre.trim();
    final normalizedEmail = correo.trim().toLowerCase();
    final normalizedPassword = contrasena.trim();

    if (normalizedName.isEmpty) {
      return 'Ingrese su nombre';
    }

    if (!_isValidEmail(normalizedEmail)) {
      return 'Ingrese un correo valido';
    }

    if (!_isValidPassword(normalizedPassword)) {
      return 'La contrasena debe tener al menos 8 caracteres';
    }

    final existingUser = await _userRepository.getUserByEmail(normalizedEmail);

    if (existingUser != null) {
      return 'El correo ya esta registrado';
    }

    final user = UserModel(
      nombre: normalizedName,
      correo: normalizedEmail,
      contrasena: PasswordHasher.hash(normalizedPassword),
      ingresoFijoMensual: 0,
      fechaRegistro: DateTime.now().toIso8601String(),
    );

    await _userRepository.insertUser(user);

    return 'Usuario registrado correctamente';
  }

  Future<UserModel?> login({
    required String correo,
    required String contrasena,
  }) async {
    final user = await _userRepository.getUserByEmail(correo);
    final normalizedPassword = contrasena.trim();

    if (user == null ||
        !PasswordHasher.verify(normalizedPassword, user.contrasena)) {
      return null;
    }

    await _userRepository.updateLastAccess(user.idUsuario!);

    if (!user.contrasena.startsWith(r'pbkdf2$')) {
      await _userRepository.updatePassword(
        idUsuario: user.idUsuario!,
        nuevaContrasena: PasswordHasher.hash(normalizedPassword),
      );
    }

    return user;
  }

  Future<String> resetPassword({
    required String correo,
    required String nuevaContrasena,
  }) async {
    final normalizedEmail = correo.trim().toLowerCase();
    final normalizedPassword = nuevaContrasena.trim();

    if (!_isValidEmail(normalizedEmail)) {
      return 'Ingrese un correo valido';
    }

    if (!_isValidPassword(normalizedPassword)) {
      return 'La contrasena debe tener al menos 8 caracteres';
    }

    final existingUser = await _userRepository.getUserByEmail(normalizedEmail);

    if (existingUser == null) {
      return 'No existe una cuenta con ese correo';
    }

    final result = await _userRepository.updatePasswordByEmail(
      correo: normalizedEmail,
      nuevaContrasena: PasswordHasher.hash(normalizedPassword),
    );

    return result > 0
        ? 'Contrasena actualizada correctamente'
        : 'No fue posible actualizar la contrasena';
  }

  Future<bool> updateUser({
    required int idUsuario,
    required String nombre,
    required String correo,
    double? ingresoFijoMensual,
  }) async {
    final normalizedName = nombre.trim();
    final normalizedEmail = correo.trim().toLowerCase();

    if (normalizedName.isEmpty || !_isValidEmail(normalizedEmail)) {
      return false;
    }

    final result = await _userRepository.updateUser({
      'id_usuario': idUsuario,
      'nombre': normalizedName,
      'correo': normalizedEmail,
    });

    return result > 0;
  }

  Future<bool> updatePassword({
    required int idUsuario,
    required String nuevaContrasena,
  }) async {
    final normalizedPassword = nuevaContrasena.trim();

    if (!_isValidPassword(normalizedPassword)) {
      return false;
    }

    final result = await _userRepository.updatePassword(
      idUsuario: idUsuario,
      nuevaContrasena: PasswordHasher.hash(normalizedPassword),
    );

    return result > 0;
  }

  Future<bool> updateFixedIncome({
    required int idUsuario,
    required double ingresoFijoMensual,
  }) async {
    if (ingresoFijoMensual < 0) {
      return false;
    }

    final result = await _userRepository.updateFixedIncome(
      idUsuario: idUsuario,
      ingresoFijoMensual: ingresoFijoMensual,
    );

    return result > 0;
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  bool _isValidPassword(String value) {
    return value.trim().length >= 8;
  }
}
