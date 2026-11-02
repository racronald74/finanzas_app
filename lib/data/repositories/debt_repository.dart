// Permite utilizar SQLite.
import 'package:sqflite/sqflite.dart';

// Helper que administra la conexión a la base de datos.
import '../database/database_helper.dart';

// Modelos de Deudas.
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';

/// Repositorio encargado de las operaciones
/// sobre las tablas deuda y pago.
///
/// Esta clase es la única que accede directamente
/// a SQLite para las operaciones de Deudas.
class DebtRepository {
  /// Instancia del helper de base de datos.
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // DEUDAS
  // ---------------------------------------------------------------------------

  /// Inserta una nueva deuda.
  Future<int> insertDebt(DebtModel debt, {DatabaseExecutor? executor}) async {
    final DatabaseExecutor db = executor ?? await _databaseHelper.database;

    return await db.insert('deuda', debt.toMap());
  }

  /// Obtiene todas las deudas de un usuario.
  ///
  /// Las deudas más recientes aparecen primero.
  Future<List<DebtModel>> getDebtsByUser(int idUsuario) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'deuda',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fecha_inicio DESC',
    );

    return result.map((item) => DebtModel.fromMap(item)).toList();
  }

  /// Obtiene una deuda por su identificador.
  ///
  /// Permite recibir un DatabaseExecutor para poder consultar
  /// la deuda utilizando la misma transacción cuando sea necesario.
  Future<DebtModel?> getDebtById(
    int idDeuda, {
    DatabaseExecutor? executor,
  }) async {
    final DatabaseExecutor db = executor ?? await _databaseHelper.database;

    final result = await db.query(
      'deuda',
      where: 'id_deuda = ?',
      whereArgs: [idDeuda],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return DebtModel.fromMap(result.first);
  }

  /// Actualiza una deuda existente.
  Future<int> updateDebt(DebtModel debt, {DatabaseExecutor? executor}) async {
    final DatabaseExecutor db = executor ?? await _databaseHelper.database;

    return await db.update(
      'deuda',
      debt.toMap(),
      where: 'id_deuda = ?',
      whereArgs: [debt.idDeuda],
    );
  }

  /// Elimina una deuda.
  Future<int> deleteDebt(int idDeuda) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      'deuda',
      where: 'id_deuda = ?',
      whereArgs: [idDeuda],
    );
  }

  // ---------------------------------------------------------------------------
  // PAGOS
  // ---------------------------------------------------------------------------

  /// Registra un nuevo pago de una deuda.
  ///
  /// Se permite recibir un DatabaseExecutor para que
  /// posteriormente DebtService pueda registrar el pago
  /// dentro de una transacción.
  Future<int> insertPayment(
    DebtPaymentModel payment, {
    DatabaseExecutor? executor,
  }) async {
    final DatabaseExecutor db = executor ?? await _databaseHelper.database;

    return await db.insert('pago', payment.toMap());
  }

  /// Obtiene todos los pagos asociados a una deuda.
  ///
  /// Los pagos más recientes aparecen primero.
  Future<List<DebtPaymentModel>> getPaymentsByDebt(int idDeuda) async {
    final Database db = await _databaseHelper.database;

    final result = await db.query(
      'pago',
      where: 'id_deuda = ?',
      whereArgs: [idDeuda],
      orderBy: 'fecha DESC',
    );

    return result.map((item) => DebtPaymentModel.fromMap(item)).toList();
  }
}
