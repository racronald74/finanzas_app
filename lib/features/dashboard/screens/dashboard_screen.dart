import 'package:flutter/material.dart';

import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_background.dart';

/// Pantalla principal del Dashboard.
class DashboardScreen extends StatelessWidget {
  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback onAvatarPressed;

  const DashboardScreen({super.key, required this.onAvatarPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cuerpo principal del Dashboard.
      body: AppBackground(
        child: Column(
          children: [
            // Encabezado reutilizable de la aplicación.
            AppHeader(
              greeting: 'Hola',
              subtitle: 'Resumen del día',
              showAvatar: true,
              showNotification: true,
              onAvatarPressed: onAvatarPressed,
            ),

            // Contenido temporal del Dashboard.
            const Expanded(
              child: Center(
                child: Text('Dashboard', style: TextStyle(fontSize: 24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
