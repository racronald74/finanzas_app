import '../database/database_helper.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import '../models/obligation_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/obligation_repository.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';

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

  /// Servicio encargado de generar y almacenar notificaciones.
  final NotificationService _notificationService = NotificationService();

  /// Estados permitidos para una obligación.
  static const String estadoPendiente = 'Pendiente';
  static const String estadoPagada = 'Pagada';

  /// Registrar una nueva obligación.
  Future<void> createObligation(ObligationModel obligation) async {
    // Valida los datos antes de registrar la obligación.
    await _validateObligation(obligation);

    // Inserta la obligación y obtiene su identificador.
    final idObligacion = await _obligationRepository.insertObligation(
      obligation,
    );

    // Las obligaciones únicas no necesitan grupo de recurrencia.
    if (obligation.esRecurrente) {
      // La obligación original identifica toda su serie recurrente.
      await _obligationRepository.updateRecurrenceGroup(
        idObligacion: idObligacion,
        idGrupoRecurrencia: idObligacion,
      );
    }

    // Consulta la obligación registrada para obtener sus datos completos.
    final nuevaObligacion = await _obligationRepository.getObligationById(
      idObligacion,
    );

    // Genera el recordatorio si cumple las condiciones establecidas.
    if (nuevaObligacion != null) {
      await _generateUpcomingObligationNotifications([nuevaObligacion]);
    }
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

  /// Obtiene una obligación específica mediante su identificador.
  ///
  /// Delega la consulta al repositorio de obligaciones.
  Future<ObligationModel?> getObligationById(int idObligacion) async {
    return await _obligationRepository.getObligationById(idObligacion);
  }

  /// Obtiene las obligaciones de un usuario.
  ///
  /// Materializa las obligaciones recurrentes del período actual
  /// y genera los recordatorios de las que vencen mañana.
  Future<List<ObligationModel>> getObligationsByUser(int idUsuario) async {
    await _materializeCurrentPeriodObligations(idUsuario);

    // Consulta las obligaciones después de materializar las recurrentes.
    final obligations = await _obligationRepository.getObligationsByUser(
      idUsuario,
    );

    // Revisa cuáles necesitan generar un recordatorio.
    await _generateUpcomingObligationNotifications(obligations);

    return obligations;
  }

  /// Sincroniza los recordatorios de las obligaciones existentes.
  Future<void> sincronizarRecordatorios(int idUsuario) async {
    // Diagnóstico temporal: confirma el inicio de la consulta.
    debugPrint('OBLIGACIONES: iniciando sincronización.');
    debugPrint('OBLIGACIONES: usuario $idUsuario.');

    // Consulta las obligaciones existentes directamente en SQLite.
    final obligations = await _obligationRepository.getObligationsByUser(
      idUsuario,
    );

    // Muestra cuántas obligaciones encontró.
    debugPrint('OBLIGACIONES: registros encontrados: ${obligations.length}.');

    // Genera únicamente los recordatorios que correspondan.
    await _generateUpcomingObligationNotifications(obligations);

    debugPrint('OBLIGACIONES: sincronización finalizada.');
  }

  /// Programa los recordatorios de obligaciones pendientes.
  ///
  /// Las alarmas locales se programan anticipadamente.
  /// El registro interno se genera únicamente el día del recordatorio.
  Future<void> _generateUpcomingObligationNotifications(
    List<ObligationModel> obligations,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final obligation in obligations) {
      // Ignora obligaciones que no tienen identificador.
      if (obligation.idObligacion == null) continue;

      final idObligacion = obligation.idObligacion!;

      // Cancela el recordatorio si no está habilitado o no está pendiente.
      if (!obligation.recordatorio || obligation.estado != estadoPendiente) {
        await _notificationService.cancelarRecordatorioObligacion(idObligacion);
        continue;
      }

      // Convierte el vencimiento a una fecha sin hora.
      final fechaVencimiento = DateTime.tryParse(obligation.fechaVencimiento);

      if (fechaVencimiento == null) {
        await _notificationService.cancelarRecordatorioObligacion(idObligacion);
        continue;
      }

      final fechaEvento = DateTime(
        fechaVencimiento.year,
        fechaVencimiento.month,
        fechaVencimiento.day,
      );

      // Calcula el día anterior al vencimiento.
      final fechaRecordatorio = fechaEvento.subtract(const Duration(days: 1));

      // Programa anticipadamente la alarma local de Android.
      await _notificationService.programarRecordatorioObligacion(
        idUsuario: obligation.idUsuario,
        idObligacion: idObligacion,
        mensaje:
            'Tu obligación ${obligation.nombre} vence mañana. '
            'Recuerda realizar el pago de \$${obligation.monto}.',
        fechaProgramada: fechaRecordatorio,
      );

      // Solo genera la notificación interna cuando corresponde el recordatorio.
      if (fechaRecordatorio.year == today.year &&
          fechaRecordatorio.month == today.month &&
          fechaRecordatorio.day == today.day) {
        await _notificationService.generarNotificacion(
          idUsuario: obligation.idUsuario,
          tipo: 'obligacion',
          mensaje:
              'Tu obligación ${obligation.nombre} vence mañana. '
              'Recuerda realizar el pago de \$${obligation.monto}.',
          idEventoOrigen: idObligacion,
          fechaEvento: fechaEvento.toIso8601String(),
          fechaProgramada: today,
        );
      }
    }
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

  /// Actualiza una obligación existente y sincroniza su recordatorio.
  Future<void> updateObligation(ObligationModel obligation) async {
    if (obligation.idObligacion == null) {
      throw Exception('La obligación no tiene un identificador');
    }

    await _validateObligation(obligation);

    // Consulta la obligación anterior para identificar sus cambios.
    final obligacionAnterior = await _obligationRepository.getObligationById(
      obligation.idObligacion!,
    );

    // Actualiza primero los datos de la obligación.
    await _obligationRepository.updateObligation(obligation);

    if (obligacionAnterior == null) return;

    final idObligacion = obligation.idObligacion!;

    // Cancela la alarma local anterior antes de programar la nueva.
    await _notificationService.cancelarRecordatorioObligacion(idObligacion);

    // Si se desactivó el recordatorio o la obligación ya no está pendiente,
    // elimina también sus notificaciones internas.
    if (!obligation.recordatorio || obligation.estado != estadoPendiente) {
      await _notificationService.eliminarNotificacionesPorEvento(
        idUsuario: obligation.idUsuario,
        tipo: 'obligacion',
        idEventoOrigen: idObligacion,
      );
      return;
    }

    // Obtiene y normaliza la nueva fecha de vencimiento.
    final fechaVencimiento = DateTime.tryParse(obligation.fechaVencimiento);

    if (fechaVencimiento == null) return;

    final fechaEvento = DateTime(
      fechaVencimiento.year,
      fechaVencimiento.month,
      fechaVencimiento.day,
    );

    // Calcula el día anterior al vencimiento.
    final fechaRecordatorio = fechaEvento.subtract(const Duration(days: 1));

    // Elimina el registro interno anterior si cambió la fecha.
    final fechaAnterior = DateTime.tryParse(
      obligacionAnterior.fechaVencimiento,
    );

    final cambioFecha =
        fechaAnterior == null ||
        fechaAnterior.year != fechaEvento.year ||
        fechaAnterior.month != fechaEvento.month ||
        fechaAnterior.day != fechaEvento.day;

    if (cambioFecha) {
      await _notificationService.eliminarNotificacionesPorEvento(
        idUsuario: obligation.idUsuario,
        tipo: 'obligacion',
        idEventoOrigen: idObligacion,
      );
    }

    // Programa la alarma local sin crear anticipadamente un registro SQLite.
    await _notificationService.programarRecordatorioObligacion(
      idUsuario: obligation.idUsuario,
      idObligacion: idObligacion,
      mensaje:
          'Tu obligación ${obligation.nombre} vence mañana. '
          'Recuerda realizar el pago de \$${obligation.monto}.',
      fechaProgramada: fechaRecordatorio,
    );

    // Genera el registro interno solamente si hoy es el día del recordatorio.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (fechaRecordatorio.year == today.year &&
        fechaRecordatorio.month == today.month &&
        fechaRecordatorio.day == today.day) {
      await _notificationService.generarNotificacion(
        idUsuario: obligation.idUsuario,
        tipo: 'obligacion',
        mensaje:
            'Tu obligación ${obligation.nombre} vence mañana. '
            'Recuerda realizar el pago de \$${obligation.monto}.',
        idEventoOrigen: idObligacion,
        fechaEvento: fechaEvento.toIso8601String(),
        fechaProgramada: today,
      );
    }
  }

  /// Elimina una obligación.
  ///
  /// Si es recurrente, desactiva toda su serie
  /// para evitar futuras generaciones.
  /// También elimina sus notificaciones pendientes.
  Future<void> deleteObligation(int idObligacion) async {
    // Consulta la obligación antes de eliminarla.
    final obligation = await _obligationRepository.getObligationById(
      idObligacion,
    );

    // Si no existe, no hay nada que eliminar.
    if (obligation == null) {
      return;
    }

    // Si es recurrente, desactiva toda su serie.
    if (obligation.esRecurrente && obligation.idGrupoRecurrencia != null) {
      await _obligationRepository.deactivateRecurrenceGroup(
        obligation.idGrupoRecurrencia!,
      );
    }

    // Cancela la alarma local independiente de la obligación.
    await _notificationService.cancelarRecordatorioObligacion(idObligacion);

    // Elimina la obligación de la base de datos.
    await _obligationRepository.deleteObligation(idObligacion);

    // Elimina sus notificaciones y cancela las alarmas programadas.
    await _notificationService.eliminarNotificacionesPorEvento(
      idUsuario: obligation.idUsuario,
      tipo: 'obligacion',
      idEventoOrigen: idObligacion,
    );
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
  /// Ambas operaciones financieras se ejecutan dentro
  /// de una única transacción SQLite.
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

    // Registra el gasto y actualiza la obligación dentro de una transacción.
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

      // Guarda el gasto asociado a la obligación.
      final idGasto = await _expenseRepository.insertExpense(
        expense,
        executor: txn,
      );

      // Actualiza el estado de la obligación y relaciona el gasto.
      final updatedObligation = obligation.copyWith(
        estado: estadoPagada,
        idGastoGenerado: idGasto,
      );

      await _obligationRepository.updateObligation(
        updatedObligation,
        executor: txn,
      );
    });

    // Cancela la alarma local independiente de la obligación.
    // El historial interno se conserva aunque la obligación esté pagada.
    await _notificationService.cancelarRecordatorioObligacion(
      obligation.idObligacion!,
    );
  }

  /// Verifica que el estado de la obligación sea válido.
  bool _isValidStatus(String estado) {
    return estado == estadoPendiente || estado == estadoPagada;
  }
}
