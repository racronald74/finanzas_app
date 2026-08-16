import '../database/database_helper.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import '../models/obligation_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/obligation_repository.dart';

/// Servicio del módulo Obligaciones.
///
/// Aquí se implementan las reglas de negocio
/// antes de acceder al repositorio.
class ObligationService {
  /// Repositorio de obligaciones.
  final ObligationRepository _obligationRepository = ObligationRepository();

  /// Repositorio de categorías.
  final CategoryRepository _categoryRepository = CategoryRepository();

  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  /// Estados permitidos para una obligación.
  static const String estadoPendiente = 'Pendiente';
  static const String estadoPagada = 'Pagada';

  /// Registrar una nueva obligación.
  Future<void> createObligation(ObligationModel obligation) async {
    await _validateObligation(obligation);

    await _obligationRepository.insertObligation(obligation);
  }

  /// Obtener todas las obligaciones de un usuario.
  Future<List<ObligationModel>> getObligationsByUser(int idUsuario) async {
    return await _obligationRepository.getObligationsByUser(idUsuario);
  }

  /// Obtener obligaciones de un usuario según su estado.
  Future<List<ObligationModel>> getObligationsByStatus(
    int idUsuario,
    String estado,
  ) async {
    if (!_isValidStatus(estado)) {
      throw Exception('Estado de obligación no válido');
    }

    return await _obligationRepository.getObligationsByStatus(
      idUsuario,
      estado,
    );
  }

  /// Actualizar una obligación existente.
  Future<void> updateObligation(ObligationModel obligation) async {
    if (obligation.idObligacion == null) {
      throw Exception('La obligación no tiene un identificador');
    }

    await _validateObligation(obligation);

    await _obligationRepository.updateObligation(obligation);
  }

  /// Eliminar una obligación.
  Future<void> deleteObligation(int idObligacion) async {
    await _obligationRepository.deleteObligation(idObligacion);
  }

  /// Valida los datos principales de una obligación.
  Future<void> _validateObligation(ObligationModel obligation) async {
    if (obligation.nombre.trim().isEmpty) {
      throw Exception('Debe ingresar un nombre para la obligación');
    }

    if (obligation.monto <= 0) {
      throw Exception('El monto debe ser mayor que cero');
    }

    if (!_isValidStatus(obligation.estado)) {
      throw Exception('Estado de obligación no válido');
    }

    await _validateCategory(obligation.idCategoria);

    if (obligation.esRecurrente) {
      if (obligation.diaVencimiento == null ||
          obligation.diaVencimiento! < 1 ||
          obligation.diaVencimiento! > 31) {
        throw Exception('El día de vencimiento debe estar entre 1 y 31');
      }

      if (obligation.frecuencia == null ||
          obligation.frecuencia!.trim().isEmpty) {
        throw Exception(
          'Debe indicar la frecuencia de una obligación recurrente',
        );
      }
    }
  }

  /// Verifica que la categoría exista y sea de tipo OBLIGACION.
  Future<void> _validateCategory(int idCategoria) async {
    final categories = await _categoryRepository.getCategoriesByType(
      'OBLIGACION',
    );

    final exists = categories.any(
      (category) => category.idCategoria == idCategoria,
    );

    if (!exists) {
      throw Exception(
        'La categoría seleccionada no es válida para una obligación',
      );
    }
  }

  /// Marca una obligación como pagada y genera
  /// automáticamente el gasto asociado.
  ///
  /// Ambas operaciones se ejecutan dentro de una
  /// misma transacción SQLite.
  Future<void> markAsPaid(ObligationModel obligation) async {
    if (obligation.idObligacion == null) {
      throw Exception('La obligación no tiene un identificador');
    }

    if (obligation.estado == estadoPagada) {
      throw Exception('La obligación ya está pagada');
    }

    if (obligation.idGastoGenerado != null) {
      throw Exception('La obligación ya tiene un gasto generado');
    }

    await _validateObligation(obligation);

    await _databaseHelper.transaction((txn) async {
      final expense = ExpenseModel(
        nombre: obligation.nombre,
        monto: obligation.monto,
        fecha: obligation.fechaVencimiento,
        descripcion: 'Gasto generado por obligación',
        idCategoria: obligation.idCategoria,
        idUsuario: obligation.idUsuario,
        origen: 'OBLIGACION',
        fechaRegistro: DateTime.now().toIso8601String(),
      );

      final idGasto = await _expenseRepository.insertExpense(
        expense,
        executor: txn,
      );

      final updatedObligation = obligation.copyWith(
        estado: estadoPagada,
        idGastoGenerado: idGasto,
      );

      await _obligationRepository.updateObligation(
        updatedObligation,
        executor: txn,
      );
    });
  }

  /// Verifica que el estado de la obligación sea válido.
  bool _isValidStatus(String estado) {
    return estado == estadoPendiente || estado == estadoPagada;
  }
}
