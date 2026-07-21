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
    /// Valor restante para completar la meta.
    final double remainingAmount = (targetAmount - savedAmount).clamp(
      0,
      double.infinity,
    );

    /// Indica si la pantalla corresponde a un dispositivo móvil.
    final bool isMobile = ResponsiveHelper.isMobile(context);

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
                /// Icono de la meta.
                CircleAvatar(
                  radius: isMobile ? 20 : 24,
                  backgroundColor: AppColors.iconBackground,
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: isMobile ? 20 : 24,
                  ),
                ),

                SizedBox(width: isMobile ? 10 : 14),

                /// Información principal.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppStatusChip(
                          text: status,
                          color: AppColors.info,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        description,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                /// Indicador circular de progreso.
                AppProgressCircle(value: progress, size: isMobile ? 46 : 60),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Valor ahorrado y objetivo.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: CurrencyFormatter.format(savedAmount),
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' / ${CurrencyFormatter.format(targetAmount)}',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// Valor restante.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Restan',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      CurrencyFormatter.format(remainingAmount),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ============================
            // Barra de progreso
            // ============================
            AppProgressBar(value: progress),

            const SizedBox(height: 22),

            const Divider(),

            const SizedBox(height: 14),

            /// Información inferior de la meta.
            Column(
              children: [
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

                const SizedBox(height: 14),

                Row(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: 130,
                      child: AppChipButton(
                        text: 'Ver detalle',
                        icon: Icons.visibility_outlined,
                        onPressed: onDetails,
                      ),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      width: 120,
                      child: AppChipButton(
                        text: 'Aportar',
                        icon: Icons.savings_outlined,
                        isPrimary: true,
                        onPressed: onContribute,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
