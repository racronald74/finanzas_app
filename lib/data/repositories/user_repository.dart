// Importa la clase Database de SQLite
import 'package:sqflite/sqflite.dart';

// Importa nuestro helper de base de datos
import '../database/database_helper.dart';

// Importa el modelo Usuario
import '../models/user_model.dart';

class UserRepository {
  // Instancia del helper para acceder a la base de datos
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Inserta un nuevo usuario en la base de datos
  Future<int> insertUser(UserModel user) async {
    // Obtiene la conexión a la base de datos
    final Database db = await _databaseHelper.database;

    // Inserta el usuario y retorna el id generado
    return await db.insert('usuario', user.toMap());
  }

  /// Busca un usuario por correo electrónico
  Future<UserModel?> getUserByEmail(String email) async {
    // Obtiene la conexión a la base de datos
    final Database db = await _databaseHelper.database;

    // Ejecuta la consulta
    final List<Map<String, dynamic>> result = await db.query(
      'usuario',
      where: 'correo = ?',
      whereArgs: [email],
    );

    // Si encuentra resultados devuelve el usuario
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }

    // Si no encuentra nada retorna null
    return null;
  }

  /// Valida credenciales para inicio de sesión
  Future<UserModel?> login(String correo, String contrasena) async {
    // Obtiene la conexión a la base de datos
    final Database db = await _databaseHelper.database;

    // Busca un usuario que coincida con correo y contraseña
    final List<Map<String, dynamic>> result = await db.query(
      'usuario',
      where: 'correo = ? AND contrasena = ?',
      whereArgs: [correo, contrasena],
    );

    // Si existe retorna el usuario
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }

    // Si no existe retorna null
    return null;
  }

  /// Actualiza los datos de un usuario existente
  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'usuario',

      user,

      where: 'id_usuario = ?',

      whereArgs: [user['id_usuario']],
    );
  }

  /// Actualiza la contraseña del usuario
  Future<int> updatePassword({
    required int idUsuario,
    required String nuevaContrasena,
  }) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'usuario',

      {'contrasena': nuevaContrasena},

      where: 'id_usuario = ?',

      whereArgs: [idUsuario],
    );
  }

  ///Metodo para actualizar el ingreso fijo mensual del usuario
  Future<int> updateFixedIncome({
    required int idUsuario,
    required double ingresoFijoMensual,
  }) async {
    final db = await DatabaseHelper.instance.database;

    return await db.update(
      'usuario',

      {'ingreso_fijo_mensual': ingresoFijoMensual},

      where: 'id_usuario = ?',

      whereArgs: [idUsuario],
    );
  }
}
