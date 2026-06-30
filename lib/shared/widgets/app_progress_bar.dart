import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// Barra de progreso reutilizable.
///
/// Se utiliza para representar el avance de:
/// - Metas.
/// - Presupuesto.
/// - Gastos.
/// - Reportes.
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

  /// Construye la barra de progreso.
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: AppColors.progressBackground,
        color: color ?? AppColors.progress,
      ),
    );
  }
}
