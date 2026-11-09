import 'package:flutter/material.dart';

import 'dashboard_header.dart';
import 'page_header.dart';
import 'more_header.dart';

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

  /// Indica si debe mostrarse el icono de configuración.
  final bool showSettings;

  /// Acción ejecutada al pulsar el icono de configuración.
  final VoidCallback? onSettingsPressed;

  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  final VoidCallback? onNotificationPressed;

  /// Acción ejecutada al pulsar regresar.
  final VoidCallback? onBackPressed;

  final bool isMoreScreen;

  const AppHeader({
    super.key,
    this.title,
    this.greeting,
    this.subtitle,
    this.showBackButton = false,
    this.showAvatar = false,
    this.showNotification = false,
    this.showSettings = false,
    this.onSettingsPressed,
    this.onAvatarPressed,
    this.isMoreScreen = false,
    this.onNotificationPressed,
    this.onBackPressed,
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
        onNotificationPressed: onNotificationPressed,
      );
    }

    if (isMoreScreen) {
      return MoreHeader(title: title ?? 'Más', userName: 'Ronald');
    }

    return PageHeader(
      title: title ?? '',
      showBackButton: showBackButton,
      showAvatar: showAvatar,
      showNotification: showNotification,
      showSettings: showSettings,
      onSettingsPressed: onSettingsPressed,
      onAvatarPressed: onAvatarPressed,
      onNotificationPressed: onNotificationPressed,
      onBackPressed: onBackPressed,
    );
  }
}
