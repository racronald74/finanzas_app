import 'package:flutter/material.dart';

import 'dashboard_header.dart';
import 'page_header.dart';

/// Encabezado reutilizable de la aplicación.
///
/// Según los parámetros recibidos muestra:
/// - El encabezado del Dashboard.
/// - El encabezado estándar del resto de pantallas.
class AppHeader extends StatelessWidget {
  /// Título utilizado en las pantallas normales.
  final String? title;

  /// Saludo mostrado en el Dashboard.
  final String? greeting;

  /// Subtítulo del Dashboard.
  final String? subtitle;

  /// Indica si debe mostrarse el botón regresar.
  final bool showBackButton;

  /// Indica si debe mostrarse el avatar.
  final bool showAvatar;

  /// Indica si debe mostrarse la campana.
  final bool showNotification;

  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  const AppHeader({
    super.key,
    this.title,
    this.greeting,
    this.subtitle,
    this.showBackButton = false,
    this.showAvatar = false,
    this.showNotification = false,
    this.onAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Determina si se utilizará el encabezado del Dashboard.
    final bool isDashboard = greeting != null && subtitle != null;

    if (isDashboard) {
      return DashboardHeader(
        greeting: greeting!,
        subtitle: subtitle!,
        showAvatar: showAvatar,
        showNotification: showNotification,
        onAvatarPressed: onAvatarPressed,
      );
    }

    return PageHeader(
      title: title ?? '',
      showBackButton: showBackButton,
      showAvatar: showAvatar,
    );
  }
}
