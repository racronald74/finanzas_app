import 'package:flutter/material.dart';
import '../../../shared/helpers/responsive_helper.dart';
import '../../../shared/themes/app_colors.dart';

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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 25),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _IndicatorItem(
                    icon: Icons.savings,
                    title: 'Ahorro total',
                    value: '\$${totalSavings.toStringAsFixed(0)}',
                    color: AppColors.primary,
                    isMobile: isMobile,
                  ),
                ),

                const VerticalDivider(),

                Expanded(
                  child: _IndicatorItem(
                    icon: Icons.track_changes,
                    title: 'Metas\nactivas',
                    value: activeGoals.toString(),
                    color: AppColors.primary,
                    isMobile: isMobile,
                  ),
                ),

                const VerticalDivider(),

                Expanded(
                  child: _IndicatorItem(
                    icon: Icons.bar_chart,
                    title: 'Progreso\ntotal',
                    value: '$totalProgress%',
                    color: AppColors.primary,
                    isMobile: isMobile,
                  ),
                ),

                const VerticalDivider(),

                Expanded(
                  child: _IndicatorItem(
                    icon: Icons.calendar_month,
                    title: 'Objetivo\nmensual',
                    value: '\$${monthlyGoal.toStringAsFixed(0)}',
                    color: AppColors.primary,
                    isMobile: isMobile,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.insights, color: Colors.blue),

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

                      Text(message, style: const TextStyle(color: Colors.grey)),
                    ],
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
          radius: isMobile ? 20 : 25,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),

        const SizedBox(height: 10),

        Text(title, textAlign: TextAlign.center),

        const SizedBox(height: 6),

        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
