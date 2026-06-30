import 'package:flutter/material.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/app_progress_bar.dart';
import '../../../shared/widgets/app_status_chip.dart';

/// Tarjeta reutilizable para mostrar una meta de ahorro.
///
/// Muestra la información principal de una meta:
/// - Icono.
/// - Nombre.
/// - Descripción.
/// - Estado.
/// - Progreso.
/// - Fecha límite.
///
/// En los siguientes pasos agregaremos:
/// - Círculo de progreso.
/// - Botones.
/// - Colores dinámicos.
class GoalCard extends StatelessWidget {
  /// Icono representativo de la meta.
  final IconData icon;

  /// Nombre de la meta.
  final String title;

  /// Descripción de la meta.
  final String description;

  /// Estado actual.
  final String status;

  /// Valor ahorrado.
  final double savedAmount;

  /// Valor objetivo.
  final double targetAmount;

  /// Progreso entre 0 y 1.
  final double progress;

  /// Fecha límite.
  final String deadline;

  /// Acción para ver el detalle.
  final VoidCallback onDetails;

  /// Acción para realizar un aporte.
  final VoidCallback onContribute;

  /// Constructor.
  const GoalCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.savedAmount,
    required this.targetAmount,
    required this.progress,
    required this.deadline,
    required this.onDetails,
    required this.onContribute,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ============================
            // Encabezado
            // ============================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.iconBackground,
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        description,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: 8),

                      AppStatusChip(text: status, color: AppColors.info),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ============================
            // Valores
            // ============================
            Row(
              children: [
                Text(
                  '\$${savedAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                Text(
                  ' / \$${targetAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ============================
            // Barra de progreso
            // ============================
            AppProgressBar(value: progress),

            const SizedBox(height: 16),

            // ============================
            // Fecha límite
            // ============================
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 8),

                const Text(
                  'Límite:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(width: 6),

                Text(
                  deadline,
                  style: const TextStyle(color: AppColors.success),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
