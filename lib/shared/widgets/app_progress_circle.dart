import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// Indicador circular reutilizable para mostrar porcentajes.
class AppProgressCircle extends StatelessWidget {
  /// Valor del progreso entre 0.0 y 1.0.
  final double value;

  /// Diámetro del indicador.
  final double size;

  /// Constructor.
  const AppProgressCircle({super.key, required this.value, this.size = 56});

  @override
  Widget build(BuildContext context) {
    // Calcula el porcentaje de progreso.
    final int percentage = (value * 100).round();

    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    // Obtiene el color principal del tema.
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: 4,

              // Adapta el fondo del indicador al tema.
              backgroundColor: highContrast
                  ? Colors.white
                  : AppColors.iconBackground,

              // Utiliza el color principal del tema.
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),

          // Muestra el porcentaje de progreso.
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highContrast ? Colors.black : primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
