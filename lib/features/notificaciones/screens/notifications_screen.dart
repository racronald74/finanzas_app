import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/app_header.dart';
import 'notification_detail_screen.dart';

/// Pantalla principal para consultar y administrar notificaciones.
class NotificationsScreen extends StatefulWidget {
  // Callback para abrir el menú lateral de la aplicación.
  final VoidCallback? onAvatarPressed;

  /// Acción ejecutada al regresar a la pantalla anterior.
  final VoidCallback? onBackPressed;

  final VoidCallback? onSettingsPressed;

  const NotificationsScreen({
    super.key,
    this.onAvatarPressed,
    this.onSettingsPressed,
    this.onBackPressed,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();

    // Carga las notificaciones existentes del usuario.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idUsuario = context.read<AuthProvider>().currentUser?.idUsuario;

      if (idUsuario != null) {
        context.read<NotificationProvider>().loadNotifications(idUsuario);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: AppBackground(
          child: Column(
            children: [
              // Encabezado con acceso a la configuración.
              AppHeader(
                title: 'Notificaciones',
                showBackButton: true,
                showAvatar: false,
                showSettings: true,
                onBackPressed: widget.onBackPressed,
                onSettingsPressed: widget.onSettingsPressed,
              ),

              // Acciones generales de las notificaciones.
              _buildActions(),

              // Filtros de notificaciones.
              Container(
                color: Colors.white,
                child: const TabBar(
                  labelColor: Color(0xFF3F73BC),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF3F73BC),
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: 'Todas'),
                    Tab(text: 'No leídas'),
                    Tab(text: 'Leídas'),
                  ],
                ),
              ),

              // Contenido de cada filtro.
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.errorMessage.isNotEmpty) {
                      return Center(
                        child: Text(
                          'Error al cargar las notificaciones:\n'
                          '${provider.errorMessage}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return TabBarView(
                      children: [
                        _buildNotificationList(provider.notifications),
                        _buildNotificationList(provider.unreadNotifications),
                        _buildNotificationList(provider.readNotifications),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la sección de acciones generales.
  Widget _buildActions() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                '${provider.unreadCount} sin leer',
                style: const TextStyle(fontSize: 14, color: Color(0xFF555555)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: provider.unreadCount == 0 ? null : _markAllAsRead,
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Marcar todas como leídas'),
              ),

              // Permite eliminar todo el historial de notificaciones.
              IconButton(
                tooltip: 'Eliminar historial',
                onPressed: provider.notifications.isEmpty
                    ? null
                    : _deleteAllNotifications,
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construye la lista de notificaciones.
  Widget _buildNotificationList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 65,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No hay notificaciones',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Agrupa las notificaciones según su fecha de recordatorio.
    final groupedNotifications = _groupNotifications(notifications);
    final dates = groupedNotifications.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final items = groupedNotifications[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5, top: 10, bottom: 8),
              child: Text(
                _formatGroupDate(date),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF355C7D),
                ),
              ),
            ),

            // Muestra las notificaciones del día.
            ...items.map(_buildNotificationCard),
          ],
        );
      },
    );
  }

  /// Obtiene la fecha en que corresponde recordar cada notificación.
  DateTime? _getReminderDate(NotificationModel notification) {
    // Normaliza el tipo de notificación.
    final tipo = notification.tipo.toLowerCase();

    // Las metas utilizan un día antes de la fecha del aporte.
    if (tipo == 'meta' && notification.fechaEvento != null) {
      return DateTime.tryParse(
        notification.fechaEvento!,
      )?.subtract(const Duration(days: 1));
    }

    // Las obligaciones utilizan un día antes del vencimiento.
    if (tipo == 'obligacion' && notification.fechaEvento != null) {
      return DateTime.tryParse(
        notification.fechaEvento!,
      )?.subtract(const Duration(days: 1));
    }

    // Las deudas utilizan la fecha del aniversario mensual.
    if (tipo == 'deuda' && notification.fechaEvento != null) {
      return DateTime.tryParse(notification.fechaEvento!);
    }

    // Los demás tipos utilizan la fecha original.
    return DateTime.tryParse(notification.fecha);
  }

  /// Agrupa las notificaciones según la fecha en que corresponde recordarlas.
  Map<DateTime, List<NotificationModel>> _groupNotifications(
    List<NotificationModel> notifications,
  ) {
    final Map<DateTime, List<NotificationModel>> grouped = {};

    for (final notification in notifications) {
      // Obtiene la fecha correspondiente al recordatorio.
      final fecha = _getReminderDate(notification);

      if (fecha == null) continue;

      // Normaliza la fecha para agrupar únicamente por día.
      final dateKey = DateUtils.dateOnly(fecha);

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(notification);
    }

    return grouped;
  }

  /// Formatea el título de cada grupo de fechas.
  String _formatGroupDate(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Hoy';
    if (date == yesterday) return 'Ayer';

    return DateFormat('d MMMM yyyy', 'es_CO').format(date);
  }

  /// Construye la tarjeta de una notificación.
  Widget _buildNotificationCard(NotificationModel notification) {
    // Obtiene el estilo visual según el tipo de notificación.
    final style = _getNotificationStyle(notification.tipo);

    // Obtiene la fecha correspondiente al recordatorio.
    final fechaRecordatorio = _getReminderDate(notification);

    // Normaliza el tipo de notificación.
    final tipo = notification.tipo.toLowerCase();

    // Formatea la fecha que corresponde mostrar.
    final String fechaTexto = fechaRecordatorio != null
        ? DateFormat('dd/MM/yyyy', 'es_CO').format(fechaRecordatorio)
        : '';

    return Dismissible(
      key: ValueKey(notification.idNotificacion),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) => _deleteNotification(notification),
      background: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 27),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 9),
        elevation: 1,
        color: notification.leida ? Colors.white : const Color(0xFFF0F5FC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),

          // Abre el detalle de la notificación seleccionada.
          onTap: () => _openNotificationDetail(notification),

          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono según el tipo de notificación.
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: style.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: style.color, size: 23),
                ),
                const SizedBox(width: 12),

                // Información de la notificación.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatNotificationType(notification.tipo),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF17324D),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.mensaje,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: Color(0xFF444444),
                        ),
                      ),
                      const SizedBox(height: 7),

                      // Muestra la fecha del recordatorio para metas y deudas.
                      Text(
                        tipo == 'meta' || tipo == 'deuda'
                            ? 'Recordatorio: $fechaTexto'
                            : DateFormat(
                                'hh:mm a',
                              ).format(DateTime.parse(notification.fecha)),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicador de notificación pendiente.
                if (!notification.leida)
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 5, left: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3F73BC),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Devuelve el estilo visual según el tipo de notificación.
  _NotificationStyle _getNotificationStyle(String tipo) {
    final normalized = tipo.toLowerCase();

    if (normalized.contains('meta')) {
      return const _NotificationStyle(
        icon: Icons.flag_outlined,
        color: Color(0xFF8B3DFF),
        background: Color(0xFFE9D9FF),
      );
    }

    if (normalized.contains('deuda')) {
      return const _NotificationStyle(
        icon: Icons.account_balance_outlined,
        color: Color(0xFFFFA000),
        background: Color(0xFFFFEDC9),
      );
    }

    if (normalized.contains('obligacion') ||
        normalized.contains('obligación') ||
        normalized.contains('pago')) {
      return const _NotificationStyle(
        icon: Icons.event_note_outlined,
        color: Color(0xFFE64A4A),
        background: Color(0xFFFFDADA),
      );
    }

    return const _NotificationStyle(
      icon: Icons.notifications_none_rounded,
      color: Color(0xFF3F73BC),
      background: Color(0xFFDCE9FA),
    );
  }

  /// Convierte el tipo técnico en un título legible.
  String _formatNotificationType(String tipo) {
    if (tipo.isEmpty) return 'Notificación';

    return tipo
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  /// Confirma la eliminación de una notificación.
  Future<bool> _confirmDelete() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar notificación'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta notificación?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Solicita confirmación antes de eliminar todo el historial.
  Future<bool> _confirmDeleteAll() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar historial'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar todas las notificaciones? '
              'Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Eliminar todo',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Abre el detalle de una notificación y la marca como leída.
  Future<void> _openNotificationDetail(NotificationModel notification) async {
    // Marca la notificación como leída antes de abrir su detalle.
    await _markAsRead(notification);

    // Verifica que la pantalla siga activa.
    if (!mounted) return;

    // Abre el detalle de la notificación.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationDetailScreen(notification: notification),
      ),
    );
  }

  /// Marca una notificación como leída.
  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.leida) return;

    final idUsuario = context.read<AuthProvider>().currentUser?.idUsuario;

    if (idUsuario == null) return;

    await context.read<NotificationProvider>().markAsRead(
      idNotificacion: notification.idNotificacion!,
      idUsuario: idUsuario,
    );
  }

  /// Marca todas las notificaciones como leídas.
  Future<void> _markAllAsRead() async {
    final idUsuario = context.read<AuthProvider>().currentUser?.idUsuario;

    if (idUsuario == null) return;

    await context.read<NotificationProvider>().markAllAsRead(idUsuario);
  }

  /// Elimina una notificación.
  Future<void> _deleteNotification(NotificationModel notification) async {
    final idUsuario = context.read<AuthProvider>().currentUser?.idUsuario;

    if (idUsuario == null) return;

    await context.read<NotificationProvider>().deleteNotification(
      idNotificacion: notification.idNotificacion!,
      idUsuario: idUsuario,
    );
  }

  /// Elimina todas las notificaciones del usuario.
  Future<void> _deleteAllNotifications() async {
    // Solicita confirmación antes de eliminar todo el historial.
    final confirmar = await _confirmDeleteAll();

    if (!confirmar || !mounted) return;

    // Obtiene el identificador del usuario autenticado.
    final idUsuario = context.read<AuthProvider>().currentUser?.idUsuario;

    if (idUsuario == null) return;

    // Elimina todas las notificaciones mediante el Provider.
    await context.read<NotificationProvider>().deleteAllNotifications(
      idUsuario,
    );
  }
}

/// Define los colores e iconos de cada tipo de notificación.
class _NotificationStyle {
  final IconData icon;
  final Color color;
  final Color background;

  const _NotificationStyle({
    required this.icon,
    required this.color,
    required this.background,
  });
}
