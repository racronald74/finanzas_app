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

  final VoidCallback? onAvatarPressed;

  const PageHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showAvatar = true,
    this.onAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFF3F6DB5)),
      child: SafeArea(
        child: Row(
          children: [
            // Botón regresar.
            if (showBackButton)
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              )
            else
              const SizedBox(width: 48),

            // Título de la pantalla.
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Avatar del usuario.
            if (showAvatar)
              GestureDetector(
                onTap: onAvatarPressed,
                child: const CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.person),
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
