import 'package:flutter/material.dart';

/// Etiqueta reutilizable para mostrar el estado de un registro.
class AppStatusChip extends StatelessWidget {
  /// Texto que identifica el estado.
  final String text;

  /// Color principal del estado.
  final Color color;

  /// Constructor del componente.
  const AppStatusChip({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // En alto contraste utiliza fondo blanco.
        color: highContrast ? Colors.white : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),

        // Agrega un borde para mejorar la identificación del estado.
        border: highContrast
            ? Border.all(color: Colors.black, width: 1.5)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          // En alto contraste utiliza texto negro.
          color: highContrast ? Colors.black : color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
