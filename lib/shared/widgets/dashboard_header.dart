import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
// Permite consultar la cantidad de notificaciones sin leer.
import '../../providers/notification_provider.dart';

/// Encabezado utilizado exclusivamente por el Dashboard.
///
/// Muestra:
/// - Avatar del usuario.
/// - Saludo.
/// - Resumen del día.
/// - Botón de notificaciones.
class DashboardHeader extends StatelessWidget {
  /// Saludo por defecto.
  final String greeting;

  /// Subtítulo del encabezado.
  final String subtitle;

  /// Indica si debe mostrarse el avatar.
  final bool showAvatar;

  /// Indica si debe mostrarse la campana.
  final bool showNotification;

  /// Acción al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  /// Acción al pulsar la campana.
  final VoidCallback? onNotificationPressed;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.showAvatar = true,
    this.showNotification = true,
    this.onAvatarPressed,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Obtiene el usuario autenticado.
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.currentUser;

    // Detecta si está activo el tema de alto contraste.
    final highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    return Container(
      // Permite que el encabezado crezca cuando el texto ocupa más espacio.
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFF3F6DB5)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          // Agrega espacio vertical para evitar que el texto quede ajustado.
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar del usuario.
              if (showAvatar)
                GestureDetector(
                  onTap: onAvatarPressed,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: highContrast
                        ? const Color(0xFF003B8E)
                        : null,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.person),
                  ),
                ),

              const SizedBox(width: 16),

              // Información del usuario.
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Hola, ${usuario?.nombre ?? greeting}\n',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: subtitle,
                        style: TextStyle(
                          color: highContrast ? Colors.white : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
              ),

              // Botón de notificaciones con indicador de mensajes sin leer.
              if (showNotification)
                Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    // Obtiene la cantidad de notificaciones pendientes de lectura.
                    final unreadCount = provider.unreadCount;

                    return IconButton(
                      onPressed: onNotificationPressed,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Icono principal de la campana.
                          const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 30,
                          ),

                          // Muestra el indicador rojo cuando existen notificaciones sin leer.
                          if (unreadCount > 0)
                            Positioned(
                              right: -8,
                              top: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 99
                                      ? '99+'
                                      : unreadCount.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
