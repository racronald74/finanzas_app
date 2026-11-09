import '../models/goal_model.dart';
import '../repositories/goal_repository.dart';
import 'notification_service.dart';
import 'package:intl/intl.dart';

/// Servicio para manejar la lógica de negocio
/// relacionada con las metas financieras.
class GoalService {
  final GoalRepository _repository = GoalRepository();

  // Servicio encargado de generar y administrar las notificaciones.
  final NotificationService _notificationService = NotificationService();

  /// Actualiza el monto acumulado de una meta después de registrar
  /// un aporte.
  ///
  /// Si el nuevo acumulado alcanza el monto objetivo,
  /// la meta pasa automáticamente a estado "Completada".
  Future actualizarMetaConAporte({
    required int idMeta,
    required int idUsuario,
    required double montoAporte,
  }) async {
    // El aporte debe ser mayor que cero.
    if (montoAporte <= 0) {
      throw ArgumentError('El monto del aporte debe ser mayor que cero');
    }

    // Obtiene la meta actual desde la base de datos.
    final GoalModel? meta = await _repository.obtenerMetaPorId(
      idMeta: idMeta,
      idUsuario: idUsuario,
    );

    if (meta == null) {
      throw ArgumentError('No se encontró la meta');
    }

    // Suma el nuevo aporte al monto acumulado.
    final double nuevoMontoAcumulado = meta.montoAcumulado + montoAporte;

    // El acumulado no puede superar el objetivo.
    final double montoFinal = nuevoMontoAcumulado > meta.montoObjetivo
        ? meta.montoObjetivo
        : nuevoMontoAcumulado;

    // Determina el estado de la meta.
    final String nuevoEstado = montoFinal >= meta.montoObjetivo
        ? 'Completada'
        : 'Activa';

    // Crea una nueva instancia de la meta conservando
    // todos sus datos y actualizando el acumulado y el estado.
    final GoalModel metaActualizada = GoalModel(
      id: meta.id,
      name: meta.name,
      category: meta.category,
      targetAmount: meta.targetAmount,
      savedAmount: montoFinal,
      deadline: meta.deadline,
      status: nuevoEstado,
      priority: meta.priority,
      reminderEnabled: meta.reminderEnabled,
      userId: meta.userId,
      completedAt: nuevoEstado == 'Completada'
          ? DateTime.now()
          : meta.completedAt,
      createdAt: meta.createdAt,
    );

    // Guarda los cambios en SQLite.
    final int resultado = await _repository.actualizarMeta(metaActualizada);

    if (resultado > 0) {
      // Sincroniza el recordatorio después del aporte.
      await _syncGoalNotification(
        metaActualizada,
        fechaAnterior: meta.deadline,
      );
    }

    return resultado;
  }

  /// Obtiene una meta utilizando únicamente su identificador.
  ///
  /// Se utiliza cuando necesitamos conocer los datos de una meta
  /// antes de realizar una operación relacionada con ella.
  Future<GoalModel?> obtenerMetaPorIdMeta(int idMeta) async {
    if (idMeta <= 0) {
      throw ArgumentError('La meta no es válida');
    }

    return await _repository.obtenerMetaPorIdMeta(idMeta);
  }

  /// Crea una nueva meta.
  Future<int> crearMeta(GoalModel meta) async {
    _validarMeta(meta);

    return await _repository.crearMeta(meta);
  }

  /// Actualiza una meta existente y sincroniza su recordatorio.
  Future<int> actualizarMeta(GoalModel meta) async {
    if (meta.idMeta == null) {
      throw ArgumentError('La meta no tiene identificador');
    }

    _validarMeta(meta);

    // Recupera la meta anterior para comparar su fecha límite.
    final GoalModel? metaAnterior = await _repository.obtenerMetaPorId(
      idMeta: meta.idMeta!,
      idUsuario: meta.idUsuario,
    );

    // Actualiza la información de la meta en SQLite.
    final int resultado = await _repository.actualizarMeta(meta);

    if (resultado > 0) {
      // Sincroniza el recordatorio con los datos actualizados.
      await _syncGoalNotification(meta, fechaAnterior: metaAnterior?.deadline);
    }

    return resultado;
  }

  /// Elimina una meta y cancela todos sus recordatorios asociados.
  Future<int> eliminarMeta({
    required int idMeta,
    required int idUsuario,
  }) async {
    // Cancela la alarma local programada para la meta.
    await _notificationService.cancelarRecordatorioMeta(idMeta);

    // Elimina las notificaciones internas asociadas a la meta.
    await _notificationService.eliminarNotificacionesPorEvento(
      idUsuario: idUsuario,
      tipo: 'meta',
      idEventoOrigen: idMeta,
    );

    // Elimina finalmente la meta de SQLite.
    return await _repository.eliminarMeta(idMeta: idMeta, idUsuario: idUsuario);
  }

  /// Obtiene una meta específica.
  Future<GoalModel?> obtenerMetaPorId({
    required int idMeta,
    required int idUsuario,
  }) async {
    return await _repository.obtenerMetaPorId(
      idMeta: idMeta,
      idUsuario: idUsuario,
    );
  }

  /// Obtiene todas las metas de un usuario.
  Future<List<GoalModel>> listarMetas(int idUsuario) async {
    // Recupera las metas registradas sin duplicar la sincronización.
    return await _repository.listarMetas(idUsuario);
  }

  /// Obtiene las metas activas.
  Future<List<GoalModel>> listarMetasActivas(int idUsuario) async {
    // Recupera únicamente las metas activas del usuario.
    return await _repository.listarMetasActivas(idUsuario);
  }

  /// Sincroniza los recordatorios de todas las metas del usuario.
  Future<void> sincronizarRecordatorios(int idUsuario) async {
    // Consulta directamente las metas registradas en SQLite.
    final List<GoalModel> metas = await _repository.listarMetas(idUsuario);

    // Programa las alarmas y recupera los registros internos pendientes.
    await _generateUpcomingGoalNotifications(metas);
  }

  /// Obtiene las metas completadas.
  Future<List<GoalModel>> listarMetasCompletadas(int idUsuario) async {
    return await _repository.listarMetasCompletadas(idUsuario);
  }

  /// Genera o sincroniza los próximos recordatorios de las metas.
  Future<void> _generateUpcomingGoalNotifications(List<GoalModel> metas) async {
    for (final GoalModel meta in metas) {
      await _programarRecordatoriosMeta(meta);
    }
  }

  /// Programa únicamente el próximo recordatorio mensual de una meta.
  Future<void> _programarRecordatoriosMeta(GoalModel meta) async {
    // No se pueden programar recordatorios sin identificador.
    if (meta.id == null) return;

    // Cancela únicamente la alarma Android cuando la meta no requiere recordatorios.
    if (!meta.reminderEnabled ||
        meta.status != 'Activa' ||
        meta.createdAt == null ||
        meta.targetAmount <= meta.savedAmount) {
      await _notificationService.cancelarRecordatorioMeta(meta.id!);
      return;
    }

    // Normaliza las fechas para comparar únicamente día, mes y año.
    final DateTime hoy = DateTime.now();
    final DateTime fechaHoy = DateTime(hoy.year, hoy.month, hoy.day);

    final DateTime fechaInicio = DateTime(
      meta.createdAt!.year,
      meta.createdAt!.month,
      meta.createdAt!.day,
    );

    final DateTime fechaLimite = DateTime(
      meta.deadline.year,
      meta.deadline.month,
      meta.deadline.day,
    );

    // Cancela únicamente la alarma Android de las metas vencidas.
    if (fechaLimite.isBefore(fechaHoy) || !fechaLimite.isAfter(fechaInicio)) {
      await _notificationService.cancelarRecordatorioMeta(meta.id!);
      return;
    }

    // Calcula el dinero que todavía falta para alcanzar el objetivo.
    final double montoRestante = meta.targetAmount - meta.savedAmount;

    // Busca los aniversarios mensuales hasta encontrar el próximo recordatorio.
    int mes = 1;
    DateTime? proximoAniversario;

    while (true) {
      // Calcula el aniversario conservando la fecha original de creación.
      final DateTime aniversario = _monthlyAnniversary(fechaInicio, mes);

      // No se consideran aportes posteriores a la fecha límite.
      if (aniversario.isAfter(fechaLimite)) {
        break;
      }

      // El recordatorio corresponde al día anterior al aporte.
      final DateTime fechaRecordatorio = aniversario.subtract(
        const Duration(days: 1),
      );

      // Evita generar recordatorios anteriores o iguales a la fecha de inicio.
      if (!fechaRecordatorio.isAfter(fechaInicio)) {
        mes++;
        continue;
      }

      // Construye el mensaje correspondiente al aniversario.
      final String mensaje =
          'Recuerda que el ${DateFormat('dd/MM/yyyy').format(aniversario)} '
          'corresponde realizar el aporte mensual de tu meta '
          '${meta.name}. Aún necesitas ahorrar '
          '\$${montoRestante.toStringAsFixed(2)} para alcanzar '
          'tu objetivo.';

      // Comprueba si el recordatorio corresponde al día actual.
      final bool recordatorioEsHoy = fechaRecordatorio.isAtSameMomentAs(
        fechaHoy,
      );

      // Genera el registro interno cuando el recordatorio ya llegó,
      // incluyendo los que corresponden al día actual.
      if (!fechaRecordatorio.isAfter(fechaHoy)) {
        // guardarNotificacionUnica evita duplicados y conserva
        // el estado de lectura de las notificaciones existentes.
        await _notificationService.generarNotificacion(
          idUsuario: meta.userId,
          tipo: 'meta',
          mensaje: mensaje,
          idEventoOrigen: meta.id!,
          fechaEvento: aniversario.toIso8601String(),
          fechaProgramada: fechaRecordatorio,
          mostrarEnAndroid: false,
        );
      }

      // Determina si todavía es posible programar la alarma
      // de las 9:00 a. m. del día actual.
      final DateTime horaRecordatorio = DateTime(
        fechaRecordatorio.year,
        fechaRecordatorio.month,
        fechaRecordatorio.day,
        9,
      );

      final bool alarmaDeHoyPendiente =
          recordatorioEsHoy && DateTime.now().isBefore(horaRecordatorio);

      // Conserva el aniversario actual si todavía no llegó
      // la hora de la alarma, o si corresponde a una fecha futura.
      if (fechaRecordatorio.isAfter(fechaHoy) || alarmaDeHoyPendiente) {
        proximoAniversario = aniversario;
        break;
      }

      // Continúa buscando el siguiente recordatorio mensual.
      mes++;
    }

    // Programa únicamente el próximo recordatorio mensual en Android.
    if (proximoAniversario != null) {
      final DateTime fechaRecordatorio = proximoAniversario.subtract(
        const Duration(days: 1),
      );

      final String mensaje =
          'Recuerda que el ${DateFormat('dd/MM/yyyy').format(proximoAniversario)} '
          'corresponde realizar el aporte mensual de tu meta '
          '${meta.name}. Aún necesitas ahorrar '
          '\$${montoRestante.toStringAsFixed(2)} para alcanzar '
          'tu objetivo.';

      await _notificationService.programarRecordatorioMeta(
        idUsuario: meta.userId,
        idMeta: meta.id!,
        mensaje: mensaje,
        fechaProgramada: fechaRecordatorio,
      );
    } else {
      // Cancela la alarma si ya no existen aniversarios pendientes.
      await _notificationService.cancelarRecordatorioMeta(meta.id!);
    }
  }

  /// Calcula un aniversario mensual desde la fecha original.
  ///
  /// Si el día original no existe en el mes de destino,
  /// utiliza el último día disponible de ese mes.
  DateTime _monthlyAnniversary(DateTime fechaInicio, int mesesAdicionales) {
    // Obtiene el mes de destino.
    final DateTime mesDestino = DateTime(
      fechaInicio.year,
      fechaInicio.month + mesesAdicionales,
      1,
    );

    // Obtiene el último día del mes de destino.
    final int ultimoDia = DateTime(
      mesDestino.year,
      mesDestino.month + 1,
      0,
    ).day;

    // Conserva el día original o utiliza el último día disponible.
    final int dia = fechaInicio.day > ultimoDia ? ultimoDia : fechaInicio.day;

    return DateTime(mesDestino.year, mesDestino.month, dia);
  }

  /// Sincroniza el recordatorio sin eliminar el historial interno.
  Future<void> _syncGoalNotification(
    GoalModel meta, {
    DateTime? fechaAnterior,
  }) async {
    // Actualiza la alarma Android según los datos actuales de la meta.
    await _programarRecordatoriosMeta(meta);
  }

  /// Valida los datos básicos de una meta.
  void _validarMeta(GoalModel meta) {
    if (meta.nombre.trim().isEmpty) {
      throw ArgumentError('El nombre de la meta es obligatorio');
    }

    if (meta.montoObjetivo <= 0) {
      throw ArgumentError('El monto objetivo debe ser mayor que cero');
    }

    if (meta.idUsuario <= 0) {
      throw ArgumentError('Usuario inválido');
    }

    if (!meta.fechaLimite.isAfter(DateTime.now())) {
      throw ArgumentError(
        'La fecha límite debe ser posterior a la fecha actual',
      );
    }

    if (meta.montoAcumulado < 0) {
      throw ArgumentError('El monto acumulado no puede ser negativo');
    }
  }

  /// Calcula el aporte mensual requerido para una meta.
  ///
  /// Se utiliza el monto que aún falta por ahorrar y
  /// el tiempo restante hasta la fecha límite.
  double calcularAporteMensual(GoalModel goal) {
    // Calcula cuánto dinero falta para completar la meta.
    final double montoRestante = (goal.montoObjetivo - goal.montoAcumulado)
        .clamp(0, double.infinity);

    // Si la meta ya está completada, no requiere nuevos aportes.
    if (montoRestante <= 0) {
      return 0;
    }

    final DateTime hoy = DateTime.now();

    // Calcula aproximadamente cuántos meses quedan
    // hasta la fecha límite de la meta.
    int mesesRestantes =
        (goal.fechaLimite.year - hoy.year) * 12 +
        goal.fechaLimite.month -
        hoy.month;

    // Si todavía estamos dentro del mes actual,
    // contamos ese mes como período disponible.
    if (goal.fechaLimite.day >= hoy.day) {
      mesesRestantes++;
    }

    // Como mínimo utilizamos un mes para evitar
    // una división entre cero.
    if (mesesRestantes < 1) {
      mesesRestantes = 1;
    }

    return montoRestante / mesesRestantes;
  }
}
