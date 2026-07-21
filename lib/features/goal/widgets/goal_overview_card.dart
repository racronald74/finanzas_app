import 'package:flutter/material.dart';
import '../../../shared/helpers/responsive_helper.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/helpers/currency_formatter.dart';

/// Tarjeta de resumen del módulo de metas.
///
/// Contiene:
/// - Indicadores principales.
/// - Mensaje de estado.
class GoalOverviewCard extends StatelessWidget {
  const GoalOverviewCard({
    super.key,
    required this.totalSavings,
    required this.activeGoals,
    required this.totalProgress,
    required this.monthlyGoal,
    required this.messageTitle,
    required this.message,
  });

  final double totalSavings;
  final int activeGoals;
  final int totalProgress;
  final double monthlyGoal;
  final String messageTitle;
  final String message;

  @override
  Widget build(BuildContext context) {
    // Indica si la aplicación se está ejecutando
    // en una pantalla de teléfono.
    final bool isMobile = ResponsiveHelper.isMobile(context);

    /// Ancho de cada indicador.
    /// Permite que el Wrap reorganice automáticamente
    /// los elementos según el espacio disponible.
    final double indicatorWidth = isMobile ? 110 : 130;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 25),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 12,
                  runSpacing: 20,
                  children: [
                    SizedBox(
                      width: indicatorWidth,
                      child: _IndicatorItem(
                        icon: Icons.savings,
                        title: 'Ahorro total',
                        value: CurrencyFormatter.format(totalSavings),
                        color: AppColors.primary,
                        isMobile: isMobile,
                      ),
                    ),

                    SizedBox(
                      width: indicatorWidth,
                      child: _IndicatorItem(
                        icon: Icons.track_changes,
                        title: 'Metas\nactivas',
                        value: activeGoals.toString(),
                        color: AppColors.primary,
                        isMobile: isMobile,
                      ),
                    ),

                    SizedBox(
                      width: indicatorWidth,
                      child: _IndicatorItem(
                        icon: Icons.bar_chart,
                        title: 'Progreso\ntotal',
                        value: '$totalProgress%',
                        color: AppColors.primary,
                        isMobile: isMobile,
                      ),
                    ),

                    SizedBox(
                      width: indicatorWidth,
                      child: _IndicatorItem(
                        icon: Icons.calendar_month,
                        title: 'Objetivo\nmensual',
                        value: CurrencyFormatter.format(monthlyGoal),
                        color: AppColors.primary,
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                const Divider(),

                const SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Icon(
                        Icons.insights,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            messageTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            message,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndicatorItem extends StatelessWidget {
  const _IndicatorItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isMobile,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  /// Indica si la pantalla es un dispositivo móvil.
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: isMobile ? 18 : 20,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: isMobile ? 18 : 22),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 15 : 16,
          ),
        ),
      ],
    );
  }
}
