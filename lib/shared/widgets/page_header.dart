import 'package:flutter/material.dart';

/// Encabezado utilizado por las pantallas de la aplicación
/// diferentes al Dashboard.
///
/// Se reutilizará en:
/// - Ingresos
/// - Gastos
/// - Metas
/// - Más
class PageHeader extends StatelessWidget {
  /// Título de la pantalla.
  final String title;

  /// Indica si debe mostrarse el botón regresar.
  final bool showBackButton;

  /// Indica si debe mostrarse el avatar.
  final bool showAvatar;

  /// Indica si debe mostrarse el icono de notificaciones.
  final bool showNotification;

  final VoidCallback? onAvatarPressed;

  const PageHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showAvatar = true,
    this.showNotification = false,
    this.onAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFF3F6DB5)),
      child: SafeArea(
        child: Row(
          children: [
            // ============================================
            // Elemento izquierdo
            // ============================================
            if (showBackButton)
              // En pantallas secundarias se mantiene
              // el botón regresar.
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
              )
            else if (showAvatar && showNotification)
              // En pantallas principales como Metas,
              // el avatar queda a la izquierda.
              GestureDetector(
                onTap: onAvatarPressed,
                child: const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person, size: 26),
                ),
              )
            else
              const SizedBox(width: 48),

            // ============================================
            // Título
            // ============================================
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ============================================
            // Elemento derecho
            // ============================================
            if (!showBackButton && showNotification)
              // Campana de notificaciones.
              IconButton(
                onPressed: () {
                  // Las notificaciones se implementarán
                  // posteriormente.
                },
                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 30,
                ),
              )
            else if (!showBackButton && showAvatar)
              // Comportamiento actual para las pantallas
              // que todavía utilizan el avatar a la derecha.
              GestureDetector(
                onTap: onAvatarPressed,
                child: const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person, size: 26),
                ),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
