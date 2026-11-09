import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Servicio encargado de administrar las notificaciones
/// locales que muestra el sistema operativo.
class LocalNotificationService {
  // Canal único utilizado por los avisos financieros en Android.
  static const String _channelId = 'finanzas_app_reminders';
  static const String _channelName = 'Recordatorios financieros';
  static const String _channelDescription =
      'Recordatorios de metas, deudas y obligaciones.';

  // Instancia principal del complemento de notificaciones.
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Evita inicializar varias veces el mismo servicio.
  bool _initialized = false;

  /// Inicializa el servicio y configura la zona horaria.
  Future<void> initialize() async {
    // Evita repetir la inicialización.
    if (_initialized) return;

    // Carga la base de datos de zonas horarias.
    tz.initializeTimeZones();

    // Obtiene la zona horaria configurada en el dispositivo.
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    // Diagnóstico temporal de la zona horaria del dispositivo.
    debugPrint('========== DIAGNÓSTICO DE ZONA HORARIA ==========');
    debugPrint('Zona detectada: ${timezoneInfo.identifier}');
    debugPrint('DateTime.now(): ${DateTime.now()}');
    debugPrint('Zona del sistema: ${DateTime.now().timeZoneName}');
    debugPrint('Desfase local: ${DateTime.now().timeZoneOffset}');

    // Normaliza el identificador GMT para que sea reconocido por timezone.
    final String identificadorZona = timezoneInfo.identifier == 'GMT'
        ? 'Etc/GMT'
        : timezoneInfo.identifier;

    // Configura la zona horaria para programar los avisos.
    tz.setLocalLocation(tz.getLocation(identificadorZona));

    // Muestra la zona horaria que utilizará el complemento.
    debugPrint('Zona configurada en timezone: ${tz.local.name}');
    debugPrint('================================================');

    // Configuración inicial para Android.
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Configuración inicial para iOS.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Configuración general de ambas plataformas.
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    // Inicializa el complemento.
    await _notificationsPlugin.initialize(settings: initializationSettings);

    _initialized = true;
  }

  /// Solicita permiso para mostrar notificaciones solamente si hace falta.
  Future<bool> requestPermissions() async {
    // Asegura que el servicio esté inicializado.
    await initialize();

    // Obtiene el complemento específico de Android.
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Comprueba si Android ya permite mostrar notificaciones.
    final permisoActual = await androidPlugin?.areNotificationsEnabled();

    // Si ya está autorizado, no vuelve a solicitarlo.
    if (permisoActual == true) return true;

    // Solicita el permiso únicamente si todavía no está concedido.
    final androidPermission = await androidPlugin
        ?.requestNotificationsPermission();

    // Devuelve el resultado según la plataforma.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidPermission ?? false;
    }

    return false;
  }

  /// Solicita permiso para programar alarmas exactas en Android.
  Future<bool> requestExactAlarmPermission() async {
    // Asegura que el servicio esté inicializado.
    await initialize();

    // Obtiene el complemento específico de Android.
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Abre los ajustes para que el usuario conceda el permiso.
    await androidPlugin?.requestExactAlarmsPermission();

    // Comprueba nuevamente si el permiso fue concedido.
    return await canScheduleExactAlarms();
  }

  /// Comprueba si Android permite programar alarmas exactas.
  Future<bool> canScheduleExactAlarms() async {
    // Obtiene el complemento específico de Android.
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Consulta el permiso actual.
    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  /// Programa una notificación para una fecha y hora determinadas.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Asegura que el servicio esté inicializado.
    await initialize();

    // No programa notificaciones con fechas anteriores al momento actual.
    if (!scheduledDate.isAfter(DateTime.now())) return;

    // Configuración visual para Android.
    const androidDetails = _androidNotificationDetails;

    // Configuración visual para iOS.
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Configuración general de la notificación.
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    // Convierte la fecha a la zona horaria configurada.
    final scheduledTimezoneDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Diagnóstico temporal de la conversión de fecha y hora.
    debugPrint('========== DIAGNÓSTICO DE PROGRAMACIÓN ==========');
    debugPrint('Fecha recibida: $scheduledDate');
    debugPrint('¿Fecha UTC?: ${scheduledDate.isUtc}');
    debugPrint('Timestamp recibido: ${scheduledDate.millisecondsSinceEpoch}');
    debugPrint('Fecha convertida: $scheduledTimezoneDate');
    debugPrint('Fecha convertida a UTC: ${scheduledTimezoneDate.toUtc()}');
    debugPrint(
      'Timestamp programado: ${scheduledTimezoneDate.millisecondsSinceEpoch}',
    );
    debugPrint('================================================');

    // Comprueba si Android permite utilizar alarmas exactas.
    final bool permisoExacto = await canScheduleExactAlarms();

    // Selecciona el modo de programación disponible.
    final AndroidScheduleMode modoProgramacion = permisoExacto
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    // Programa la notificación en Android.
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTimezoneDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: modoProgramacion,
      payload: payload,
    );
  }

  /// Muestra una notificación inmediatamente.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Asegura que el servicio esté inicializado.
    await initialize();

    // Configuración visual para Android.
    const androidDetails = _androidNotificationDetails;

    // Configuración visual para iOS.
    const darwinDetails = DarwinNotificationDetails();

    // Configuración general.
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    // Muestra la notificación.
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Cancela una notificación por su identificador.
  Future<void> cancelNotification(int id) async {
    await initialize();

    await _notificationsPlugin.cancel(id: id);
  }

  /// Cancela todas las notificaciones pendientes y visibles.
  Future<void> cancelAllNotifications() async {
    await initialize();

    await _notificationsPlugin.cancelAll();
  }

  /// Consulta las notificaciones que todavía están programadas.
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    // Asegura que el servicio esté inicializado.
    await initialize();

    // Devuelve las notificaciones pendientes de Android.
    return _notificationsPlugin.pendingNotificationRequests();
  }

  /// Muestra en consola las notificaciones que Android tiene programadas.
  Future<void> diagnosticarNotificacionesPendientes() async {
    // Consulta las notificaciones pendientes del sistema.
    final notificaciones = await getPendingNotifications();

    // Muestra la cantidad de notificaciones encontradas.
    debugPrint('========== DIAGNÓSTICO DE NOTIFICACIONES ==========');
    debugPrint('Total pendientes: ${notificaciones.length}');

    // Muestra los datos de cada notificación.
    for (final notificacion in notificaciones) {
      debugPrint('ID: ${notificacion.id}');
      debugPrint('Título: ${notificacion.title}');
      debugPrint('Contenido: ${notificacion.body}');
      debugPrint('------------------------------------------------');
    }

    debugPrint('========== FIN DEL DIAGNÓSTICO ==========');
  }

  /// Configuración compartida que conserva el sonido del canal Android.
  static const AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

  /// Obtiene el título visible correspondiente a cada tipo de recordatorio.
  static String obtenerTitulo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'meta':
        return 'Recordatorio de meta';
      case 'deuda':
        return 'Recordatorio de deuda';
      case 'obligacion':
        return 'Recordatorio de obligación';
      default:
        return 'FinanzasApp';
    }
  }
}
