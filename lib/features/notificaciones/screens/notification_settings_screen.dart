import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';

/// Pantalla para configurar las preferencias de notificaciones.
class NotificationSettingsScreen extends StatefulWidget {
  /// Callback para regresar a la pantalla de notificaciones.
  final VoidCallback onBackPressed;

  /// Callback para abrir el menú lateral desde el avatar.
  final VoidCallback? onAvatarPressed;

  const NotificationSettingsScreen({
    super.key,
    required this.onBackPressed,
    this.onAvatarPressed,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificacionesActivas = true;
  bool _notificacionesMetas = true;
  bool _notificacionesDeudas = true;
  bool _notificacionesObligaciones = true;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Carga las preferencias después de construir la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  /// Consulta las preferencias almacenadas para el usuario autenticado.
  Future<void> _loadSettings() async {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();

    final int? idUsuario = authProvider.currentUser?.idUsuario;

    if (idUsuario == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    await notificationProvider.loadNotificationSettings(idUsuario);

    if (!mounted) return;

    final settings = notificationProvider.notificationSettings;

    if (settings != null) {
      setState(() {
        _notificacionesActivas = settings.notificacionesActivas;
        _notificacionesMetas = settings.notificacionesMetas;
        _notificacionesDeudas = settings.notificacionesDeudas;
        _notificacionesObligaciones = settings.notificacionesObligaciones;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });

      _showMessage(
        notificationProvider.errorMessage.isNotEmpty
            ? notificationProvider.errorMessage
            : 'No se pudieron cargar las preferencias.',
      );
    }
  }

  /// Guarda automáticamente las preferencias modificadas.
  Future<void> _saveSettings() async {
    final int? idUsuario = context.read<AuthProvider>().currentUser?.idUsuario;

    if (idUsuario == null) {
      _showMessage('No se pudo identificar al usuario.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final bool success = await context
        .read<NotificationProvider>()
        .updateNotificationSettings(
          idUsuario: idUsuario,
          notificacionesActivas: _notificacionesActivas,
          notificacionesMetas: _notificacionesMetas,
          notificacionesDeudas: _notificacionesDeudas,
          notificacionesObligaciones: _notificacionesObligaciones,
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (!success) {
      _showMessage('No se pudieron guardar las preferencias.');
    }
  }

  /// Muestra mensajes informativos al usuario.
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preferencias',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF17324D),
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Administra las notificaciones que deseas recibir.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF667085),
                            ),
                          ),

                          const SizedBox(height: 20),

                          _buildSwitchTile(
                            title: 'Notificaciones generales',
                            subtitle:
                                'Activar o desactivar todas las notificaciones.',
                            value: _notificacionesActivas,
                            onChanged: (value) {
                              setState(() {
                                _notificacionesActivas = value;
                              });
                              _saveSettings();
                            },
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Tipos de notificaciones',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF17324D),
                            ),
                          ),

                          const SizedBox(height: 10),

                          _buildSwitchTile(
                            title: 'Metas',
                            subtitle:
                                'Recordatorios y avisos relacionados con tus metas.',
                            value: _notificacionesMetas,
                            enabled: _notificacionesActivas,
                            onChanged: (value) {
                              setState(() {
                                _notificacionesMetas = value;
                              });
                              _saveSettings();
                            },
                          ),

                          const SizedBox(height: 10),

                          _buildSwitchTile(
                            title: 'Deudas',
                            subtitle:
                                'Recordatorios y avisos relacionados con tus deudas.',
                            value: _notificacionesDeudas,
                            enabled: _notificacionesActivas,
                            onChanged: (value) {
                              setState(() {
                                _notificacionesDeudas = value;
                              });
                              _saveSettings();
                            },
                          ),

                          const SizedBox(height: 10),

                          _buildSwitchTile(
                            title: 'Obligaciones',
                            subtitle:
                                'Recordatorios y avisos de tus obligaciones.',
                            value: _notificacionesObligaciones,
                            enabled: _notificacionesActivas,
                            onChanged: (value) {
                              setState(() {
                                _notificacionesObligaciones = value;
                              });
                              _saveSettings();
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el encabezado siguiendo el diseño de AddObligationScreen.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: const Color(0xFF3F73BC),
      child: Row(
        children: [
          // Regresa a la pantalla anterior.
          IconButton(
            onPressed: widget.onBackPressed,
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),

          const SizedBox(width: 2),

          const Expanded(
            child: Text(
              'Configuración de notificaciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Avatar para abrir el menú lateral.
          GestureDetector(
            onTap: widget.onAvatarPressed,
            child: const CircleAvatar(
              radius: 22,
              child: Icon(Icons.person, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una opción de configuración con interruptor.
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD5E1ED)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
        value: value,
        activeThumbColor: const Color(0xFF2196F3),
        onChanged: enabled && !_isSaving ? onChanged : null,
      ),
    );
  }
}
