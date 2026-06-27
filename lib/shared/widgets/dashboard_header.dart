import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

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

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.showAvatar = true,
    this.showNotification = true,
    this.onAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Obtiene el usuario autenticado.
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.currentUser;

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFF3F6DB5)),
      child: SafeArea(
        child: Row(
          children: [
            // Avatar del usuario.
            if (showAvatar)
              GestureDetector(
                onTap: onAvatarPressed,
                child: const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person),
                ),
              ),

            const SizedBox(width: 16),

            // Información del usuario.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${usuario?.nombre ?? greeting}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Botón de notificaciones.
            if (showNotification)
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
