import 'package:flutter/material.dart';

/// Encabezado específico del módulo de Ingresos.
///
/// Permite mostrar:
/// - Avatar del usuario.
/// - Título del módulo.
/// - Período seleccionado.
/// - Botón para seleccionar el período.
class IncomeHeader extends StatelessWidget {
  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  /// Acción ejecutada al pulsar el calendario.
  final VoidCallback? onCalendarPressed;

  /// Texto que representa el período seleccionado.
  final String periodText;

  const IncomeHeader({
    super.key,
    this.onAvatarPressed,
    this.onCalendarPressed,
    this.periodText = 'Mes actual - Febrero 2026',
  });

  @override
  Widget build(BuildContext context) {
    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    // Define los colores según el tema activo.
    final Color backgroundColor = highContrast
        ? Colors.white
        : const Color(0xFF3F6DB5);

    final Color foregroundColor = highContrast ? Colors.black : Colors.white;

    final Color iconColor = highContrast
        ? const Color(0xFF003B8E)
        : Colors.white;

    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: highContrast
            ? const Border(bottom: BorderSide(color: Colors.black, width: 2))
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar del usuario.
              GestureDetector(
                onTap: onAvatarPressed,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: highContrast ? Colors.white : null,
                  foregroundColor: iconColor,
                  child: Icon(Icons.person, size: 26, color: iconColor),
                ),
              ),

              const SizedBox(width: 16),

              // Título y período seleccionado.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ingresos',
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      periodText,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: foregroundColor, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Botón para seleccionar el período.
              IconButton(
                onPressed: onCalendarPressed,
                icon: Icon(Icons.calendar_month, color: iconColor, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
