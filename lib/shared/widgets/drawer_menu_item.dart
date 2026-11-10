import 'package:flutter/material.dart';

/// Opción reutilizable del Drawer.
///
/// Evita duplicar código para cada elemento del menú.
class DrawerMenuItem extends StatelessWidget {
  /// Icono de la opción.
  final IconData icon;

  /// Texto principal.
  final String title;

  /// Acción al pulsar la opción.
  final VoidCallback onTap;

  /// Color del icono.
  final Color iconColor;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    // Detecta si está activo el modo de alto contraste.
    final highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    return ListTile(
      // Conserva el color específico de cada icono.
      leading: Icon(
        icon,
        color: highContrast && iconColor == Colors.black87
            ? Colors.black
            : iconColor,
      ),

      // Mejora la legibilidad del texto en alto contraste.
      title: Text(
        title,
        style: TextStyle(color: highContrast ? Colors.black : null),
      ),

      // Flecha de navegación con contraste suficiente.
      trailing: Icon(
        Icons.chevron_right,
        color: highContrast ? Colors.black : null,
      ),

      onTap: onTap,
    );
  }
}
