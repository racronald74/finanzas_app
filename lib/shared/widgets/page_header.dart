import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

/// Encabezado utilizado por las pantallas de la aplicación
/// diferentes al Dashboard.
///
/// Se reutilizará en:
/// - Ingresos
/// - Gastos
/// - Metas
/// - Más
class PageHeader extends StatefulWidget {
  /// Título de la pantalla.
  final String title;

  /// Indica si debe mostrarse el botón regresar.
  final bool showBackButton;

  /// Indica si debe mostrarse el avatar.
  final bool showAvatar;

  /// Indica si debe mostrarse el icono de notificaciones.
  final bool showNotification;

  /// Indica si debe mostrarse el icono de configuración.
  final bool showSettings;

  /// Acción ejecutada al pulsar el icono de configuración.
  final VoidCallback? onSettingsPressed;

  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  /// Acción ejecutada al pulsar la campana.
  final VoidCallback? onNotificationPressed;

  /// Acción personalizada al pulsar regresar.
  final VoidCallback? onBackPressed;

  const PageHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showAvatar = true,
    this.showNotification = false,
    this.showSettings = false,
    this.onSettingsPressed,
    this.onAvatarPressed,
    this.onNotificationPressed,
    this.onBackPressed,
  });

  @override
  State<PageHeader> createState() => _PageHeaderState();
}

class _PageHeaderState extends State<PageHeader> {
  @override
  void initState() {
    super.initState();

    // Carga las notificaciones después de construir el encabezado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  /// Obtiene las notificaciones del usuario autenticado.
  Future<void> _loadNotifications() async {
    final idUsuario = context.read<AuthProvider>().currentUser?.idUsuario;

    if (idUsuario != null && mounted) {
      await context.read<NotificationProvider>().loadNotifications(idUsuario);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFF3F6DB5)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            children: [
              // ============================================
              // Elemento izquierdo
              // ============================================
              if (widget.showBackButton)
                // Botón regresar para pantallas secundarias.
                IconButton(
                  onPressed:
                      widget.onBackPressed ?? () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                )
              else if (widget.showAvatar && widget.showNotification)
                // Avatar ubicado a la izquierda.
                GestureDetector(
                  onTap: widget.onAvatarPressed,
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
                  // Evita que el título pase a una segunda línea.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // ============================================
              // Elemento derecho
              // ============================================
              if (widget.showSettings)
                // Engranaje para abrir la configuración.
                IconButton(
                  onPressed: widget.onSettingsPressed,
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                )
              else if (!widget.showBackButton && widget.showNotification)
                // Campana con contador de notificaciones pendientes.
                Consumer<NotificationProvider>(
                  builder: (context, provider, child) {
                    final unreadCount = provider.unreadCount;

                    return IconButton(
                      onPressed: widget.onNotificationPressed,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 30,
                          ),

                          // El indicador solo aparece si hay pendientes.
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
                )
              else if (!widget.showBackButton && widget.showAvatar)
                // Avatar ubicado a la derecha.
                GestureDetector(
                  onTap: widget.onAvatarPressed,
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
      ),
    );
  }
}
