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

    final idObligacion = await _obligationRepository.insertObligation(
      obligation,
    );

    // Las obligaciones únicas no necesitan grupo de recurrencia.
    if (!obligation.esRecurrente) {
      return;
    }

    // La obligación original se convierte en el identificador
    // de toda su serie recurrente.
    await _obligationRepository.updateRecurrenceGroup(
      idObligacion: idObligacion,
      idGrupoRecurrencia: idObligacion,
    );
  }

  /// Calcula la siguiente fecha de vencimiento según la frecuencia.
  DateTime? _calculateNextDate(DateTime fecha, String? frecuencia) {
    switch (frecuencia) {
      case 'Mensual':
        return DateTime(fecha.year, fecha.month + 1, fecha.day);

      case 'Trimestral':
        return DateTime(fecha.year, fecha.month + 3, fecha.day);

      case 'Semestral':
        return DateTime(fecha.year, fecha.month + 6, fecha.day);

      case 'Anual':
        return DateTime(fecha.year + 1, fecha.month, fecha.day);

      default:
        return null;
    }
  }

  /// Obtiene las obligaciones de un usuario.
  ///
  /// Antes de devolverlas, materializa las obligaciones
  /// recurrentes que correspondan al período actual.
  Future<List<ObligationModel>> getObligationsByUser(int idUsuario) async {
    await _materializeCurrentPeriodObligations(idUsuario);

    return await _obligationRepository.getObligationsByUser(idUsuario);
  }

  /// Crea las obligaciones recurrentes correspondientes
  /// al período actual cuando todavía no existen.
  Future<void> _materializeCurrentPeriodObligations(int idUsuario) async {
    final obligations = await _obligationRepository.getObligationsByUser(
      idUsuario,
    );

    final now = DateTime.now();

    for (final obligation in obligations) {
      // Las obligaciones únicas no generan nuevas ocurrencias.
      if (!obligation.esRecurrente) {
        continue;
      }

      // Si el usuario canceló la recurrencia,
      // no debe volver a materializarse.
      if (!obligation.recurrenciaActiva) {
        continue;
      }

      final fechaOriginal = DateTime.tryParse(obligation.fechaVencimiento);

      if (fechaOriginal == null) {
        continue;
      }

      DateTime? siguienteFecha = fechaOriginal;

      // Avanza según la frecuencia hasta encontrar
      // el vencimiento correspondiente al período actual.
      while (siguienteFecha != null &&
          (siguienteFecha.year < now.year ||
              (siguienteFecha.year == now.year &&
                  siguienteFecha.month < now.month))) {
        siguienteFecha = _calculateNextDate(
          siguienteFecha,
          obligation.frecuencia,
        );
      }

      if (siguienteFecha == null) {
        continue;
      }

      // Solo materializa obligaciones cuyo vencimiento
      // pertenece al período actual.
      if (siguienteFecha.year != now.year ||
          siguienteFecha.month != now.month) {
        continue;
      }

      final fechaVencimiento = siguienteFecha.toIso8601String();

      final existente = await _obligationRepository
          .getRecurringObligationByPeriod(
            idUsuario: idUsuario,
            nombre: obligation.nombre,
            frecuencia: obligation.frecuencia!,
            year: siguienteFecha.year,
            month: siguienteFecha.month,
          );

      if (existente != null) {
        continue;
      }

      final nuevaObligacion = ObligationModel(
        nombre: obligation.nombre,
        monto: obligation.monto,
        idCategoria: obligation.idCategoria,
        fechaVencimiento: fechaVencimiento,
        recordatorio: obligation.recordatorio,
        estado: estadoPendiente,
        esRecurrente: obligation.esRecurrente,
        diaVencimiento: obligation.diaVencimiento,
        idUsuario: obligation.idUsuario,
        idGastoGenerado: null,
        fechaRegistro: DateTime.now().toIso8601String(),
        frecuencia: obligation.frecuencia,
        // Mantiene la nueva ocurrencia dentro de la misma
        // serie de recurrencia.
        idGrupoRecurrencia: obligation.idGrupoRecurrencia,
      );

      await _obligationRepository.insertObligation(nuevaObligacion);
    }
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

  /// Elimina una obligación.
  ///
  /// Si es recurrente, desactiva toda su serie
  /// para evitar futuras generaciones.
  Future<void> deleteObligation(int idObligacion) async {
    final obligation = await _obligationRepository.getObligationById(
      idObligacion,
    );

    if (obligation == null) {
      return;
    }

    if (obligation.esRecurrente && obligation.idGrupoRecurrencia != null) {
      await _obligationRepository.deactivateRecurrenceGroup(
        obligation.idGrupoRecurrencia!,
      );
    }

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
