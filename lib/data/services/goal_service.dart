import '../models/goal_model.dart';
import '../repositories/goal_repository.dart';

/// Servicio para manejar la lógica de negocio
/// relacionada con las metas financieras.
class GoalService {
  final GoalRepository _repository = GoalRepository();

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
    return await _repository.actualizarMeta(metaActualizada);
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

  /// Actualiza una meta existente.
  Future<int> actualizarMeta(GoalModel meta) async {
    if (meta.idMeta == null) {
      throw ArgumentError('La meta no tiene identificador');
    }

    _validarMeta(meta);

    return await _repository.actualizarMeta(meta);
  }

  /// Elimina una meta.
  Future<int> eliminarMeta({
    required int idMeta,
    required int idUsuario,
  }) async {
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
    return await _repository.listarMetas(idUsuario);
  }

  /// Obtiene las metas activas.
  Future<List<GoalModel>> listarMetasActivas(int idUsuario) async {
    return await _repository.listarMetasActivas(idUsuario);
  }

  /// Obtiene las metas completadas.
  Future<List<GoalModel>> listarMetasCompletadas(int idUsuario) async {
    return await _repository.listarMetasCompletadas(idUsuario);
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
