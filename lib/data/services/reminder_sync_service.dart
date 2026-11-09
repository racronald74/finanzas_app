import 'goal_service.dart';
import 'obligation_service.dart';
import 'debt_service.dart';
import 'notification_service.dart';

/// Servicio encargado de centralizar la sincronización
/// de recordatorios de los módulos financieros.
class ReminderSyncService {
  // Servicios de cada módulo.
  final GoalService _goalService = GoalService();
  final DebtService _debtService = DebtService();
  final ObligationService _obligationService = ObligationService();
  // Servicio encargado de gestionar y limpiar las notificaciones.
  final NotificationService _notificationService = NotificationService();

  /// Sincroniza los recordatorios de un usuario.
  ///
  /// Primero limpia los duplicados existentes y después
  /// sincroniza los recordatorios de los módulos financieros.
  Future<void> sincronizarRecordatorios(int idUsuario) async {
    // Elimina duplicados de metas y cancela sus alarmas en Android.
    await _notificationService.limpiarDuplicadosMetas(idUsuario);

    // Consulta las metas y genera sus recordatorios.
    await _goalService.listarMetas(idUsuario);

    // Consulta las deudas y genera sus recordatorios.
    await _debtService.getDebtsByUser(idUsuario);

    // Consulta las obligaciones existentes sin materializar
    // nuevas ocurrencias recurrentes.
    await _obligationService.sincronizarRecordatorios(idUsuario);
  }
}
