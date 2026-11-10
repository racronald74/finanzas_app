import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// Barra de progreso reutilizable.
class AppProgressBar extends StatelessWidget {
  /// Valor del progreso entre 0 y 1.
  final double value;

  /// Altura de la barra.
  final double height;

  /// Color del progreso.
  final Color? color;

  /// Constructor de la barra de progreso.
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    // Obtiene los colores según el tema activo.
    final Color backgroundColor = highContrast
        ? Colors.white
        : AppColors.progressBackground;

    final Color progressColor =
        color ??
        (highContrast
            ? Theme.of(context).colorScheme.primary
            : AppColors.progress);

    return Container(
      // Agrega un borde negro para mejorar la visibilidad.
      decoration: highContrast
          ? BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LinearProgressIndicator(
          // Limita el progreso al intervalo permitido.
          value: value.clamp(0.0, 1.0),
          minHeight: height,
          backgroundColor: backgroundColor,
          color: progressColor,
        ),
      ),
    );
  }
}
