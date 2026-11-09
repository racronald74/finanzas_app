import 'package:flutter/material.dart';

import '../../../data/models/notification_model.dart';
import 'package:intl/intl.dart';

/// Pantalla que muestra la información completa de una notificación.
class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({super.key, required this.notification});

  /// Convierte el tipo interno en un nombre comprensible.
  String _getCategoryName() {
    switch (notification.tipo) {
      case 'meta':
        return 'Meta';
      case 'deuda':
        return 'Deuda';
      case 'obligacion':
        return 'Obligación';
      default:
        return 'Notificación';
    }
  }

  /// Obtiene el icono correspondiente a la categoría.
  IconData _getCategoryIcon() {
    switch (notification.tipo) {
      case 'meta':
        return Icons.flag_outlined;
      case 'deuda':
        return Icons.account_balance_wallet_outlined;
      case 'obligacion':
        return Icons.event_note_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// Obtiene la fecha en que debe realizarse el recordatorio.
  String _formatReminderDate() {
    // Las notificaciones de metas se programan un día antes del aporte.
    if (notification.tipo.toLowerCase() == 'meta' &&
        notification.fechaEvento != null) {
      final fechaAporte = DateTime.tryParse(notification.fechaEvento!);

      if (fechaAporte != null) {
        final fechaRecordatorio = fechaAporte.subtract(const Duration(days: 1));

        return DateFormat('dd/MM/yyyy', 'es_CO').format(fechaRecordatorio);
      }
    }

    // Para otros tipos se conserva la fecha de creación del registro.
    final fecha = DateTime.tryParse(notification.fecha);

    if (fecha == null) return notification.fecha;

    return DateFormat('dd/MM/yyyy - hh:mm a', 'es_CO').format(fecha);
  }

  /// Obtiene la fecha correspondiente al aporte mensual.
  String _formatEventDate() {
    final fecha = DateTime.tryParse(notification.fechaEvento ?? '');

    if (fecha == null) return 'No disponible';

    return DateFormat('dd/MM/yyyy', 'es_CO').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de notificación')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono y categoría de la notificación.
            Center(
              child: Column(
                children: [
                  Icon(
                    _getCategoryIcon(),
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getCategoryName(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Mensaje completo del aviso.
            Text('Información', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  notification.mensaje,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// Fecha en que debe realizarse el recordatorio.
            Text(
              'Fecha del recordatorio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(_formatReminderDate()),

            const SizedBox(height: 24),

            // Fecha correspondiente al aporte mensual.
            if (notification.tipo.toLowerCase() == 'meta') ...[
              Text(
                'Fecha del aporte',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_formatEventDate()),
              const SizedBox(height: 24),
            ],

            // Estado actual de lectura.
            Text('Estado', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(notification.leida ? 'Leída' : 'No leída'),
          ],
        ),
      ),
    );
  }
}
