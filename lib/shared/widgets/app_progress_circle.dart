import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// Indicador circular reutilizable para mostrar porcentajes.
///
/// Se utilizará en:
/// - Metas.
/// - Dashboard.
/// - Reportes.
/// - Otros módulos que requieran mostrar progreso.
class AppProgressCircle extends StatelessWidget {
  /// Valor del progreso entre 0.0 y 1.0.
  final double value;

  /// Diámetro del indicador.
  final double size;

  /// Constructor.
  const AppProgressCircle({super.key, required this.value, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final int percentage = (value * 100).round();

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
              value: value,
              strokeWidth: 5,
              backgroundColor: AppColors.iconBackground,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),

          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
