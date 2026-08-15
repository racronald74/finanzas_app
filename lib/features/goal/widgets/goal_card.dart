import 'package:flutter/material.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/app_progress_bar.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_progress_circle.dart';
import '../../../shared/helpers/responsive_helper.dart';
import '../../../shared/widgets/app_chip_button.dart';
import '../../../shared/helpers/currency_formatter.dart';

/// Tarjeta reutilizable para mostrar una meta de ahorro.
///
/// Muestra la información principal de una meta:
/// - Icono.
/// - Nombre.
/// - Descripción.
/// - Estado.
/// - Progreso.
/// - Fecha límite.

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
    /// Calcula cuánto dinero falta para alcanzar la meta.
    final double remainingAmount = (targetAmount - savedAmount).clamp(
      0,
      double.infinity,
    );

    /// Indica si la pantalla corresponde a un dispositivo móvil.
    final bool isMobile = ResponsiveHelper.isMobile(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ============================================
            // Encabezado de la meta
            // ============================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono representativo de la meta.
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: CircleAvatar(
                    radius: isMobile ? 24 : 28,
                    backgroundColor: AppColors.iconBackground,
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: isMobile ? 24 : 28,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Nombre, categoría y estado.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre y estado de la meta.
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // Estado mostrado junto al nombre.
                          AppStatusChip(text: status, color: AppColors.info),
                        ],
                      ),

                      // Categoría de la meta.
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Porcentaje de progreso.
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: AppProgressCircle(
                    value: progress,
                    size: isMobile ? 46 : 54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ============================================
            // Montos y dinero restante
            // ============================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Monto ahorrado y objetivo.
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.format(savedAmount),
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: isMobile ? 15 : 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${CurrencyFormatter.format(targetAmount)}',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: isMobile ? 13 : 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dinero que todavía falta.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Restan',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      CurrencyFormatter.format(remainingAmount),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ============================================
            // Barra de progreso
            // ============================================
            AppProgressBar(value: progress, height: 8),

            const SizedBox(height: 12),

            const Divider(height: 1),

            const SizedBox(height: 10),

            // ============================================
            // Fecha límite y acciones
            // ============================================
            Row(
              children: [
                // Fecha límite.
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Límite:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          deadline,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Botón para ver el detalle.
                SizedBox(
                  width: 100,
                  height: 33,
                  child: AppChipButton(
                    text: 'Ver detalle',
                    primaryColor: AppColors.success,
                    onPressed: onDetails,
                  ),
                ),

                const SizedBox(width: 6),

                // Botón para registrar un aporte.
                SizedBox(
                  width: 85,
                  height: 33,
                  child: AppChipButton(
                    text: 'Aportar',
                    isPrimary: true,
                    primaryColor: AppColors.success,
                    onPressed: onContribute,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
