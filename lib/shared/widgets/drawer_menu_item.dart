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
    return ListTile(
      leading: Icon(icon, color: iconColor),

      title: Text(title),

      trailing: const Icon(Icons.chevron_right),

      onTap: onTap,
    );
  }
}
