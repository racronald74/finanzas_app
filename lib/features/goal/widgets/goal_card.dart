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

    /// Comprueba si la meta ya alcanzó su objetivo.
    final bool isGoalCompleted = remainingAmount <= 0;

    /// Indica si la pantalla corresponde a un dispositivo móvil.
    final bool isMobile = ResponsiveHelper.isMobile(context);

    /// Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    /// Obtiene los colores del tema actual.
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color textColor = highContrast ? Colors.black : AppColors.textPrimary;
    final Color secondaryColor = highContrast
        ? Colors.black
        : AppColors.textSecondary;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;

    return Card(
      // Adapta el fondo y el borde al tema activo.
      color: surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: highContrast ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: highContrast
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Encabezado de la meta.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono representativo de la meta.
                CircleAvatar(
                  radius: isMobile ? 24 : 28,
                  backgroundColor: highContrast
                      ? Colors.white
                      : AppColors.iconBackground,
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: isMobile ? 24 : 28,
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
                                color: textColor,
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Estado mostrado junto al nombre.
                          AppStatusChip(
                            text: status,
                            color: highContrast ? Colors.black : AppColors.info,
                          ),
                        ],
                      ),

                      // Categoría de la meta.
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: secondaryColor, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Porcentaje de progreso.
                AppProgressCircle(value: progress, size: isMobile ? 46 : 54),
              ],
            ),

            const SizedBox(height: 8),

            // Montos y dinero restante.
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
                            color: highContrast
                                ? Colors.black
                                : AppColors.success,
                            fontSize: isMobile ? 15 : 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${CurrencyFormatter.format(targetAmount)}',
                          style: TextStyle(
                            color: textColor,
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
                    Text(
                      'Restan',
                      style: TextStyle(color: secondaryColor, fontSize: 13),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      CurrencyFormatter.format(remainingAmount),
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Barra de progreso.
            AppProgressBar(value: progress, height: 8),

            const SizedBox(height: 12),

            // Separador visual.
            Divider(
              height: 1,
              thickness: highContrast ? 1.5 : 1,
              color: highContrast ? Colors.black : null,
            ),

            const SizedBox(height: 10),

            // Fecha límite y acciones.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fecha límite.
                Row(
                  children: [
                    Icon(Icons.calendar_month, size: 17, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'Límite:',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 5),

                    // La fecha ocupa el espacio disponible.
                    Expanded(
                      child: Text(
                        deadline,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: highContrast
                              ? Colors.black
                              : AppColors.success,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Botones ubicados debajo de la fecha.
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Botón para ver el detalle.
                    SizedBox(
                      width: 100,
                      height: 33,
                      child: AppChipButton(
                        text: 'Ver detalle',
                        primaryColor: highContrast
                            ? primaryColor
                            : AppColors.success,
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
                        primaryColor: highContrast
                            ? primaryColor
                            : AppColors.success,
                        // Deshabilita el aporte cuando la meta está completada.
                        onPressed: isGoalCompleted ? null : onContribute,
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
