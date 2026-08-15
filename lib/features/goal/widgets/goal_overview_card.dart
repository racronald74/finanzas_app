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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 25),
            child: Column(
              children: [
                // ============================================
                // Indicadores principales
                // ============================================
                //
                // Los cuatro indicadores permanecen en una
                // sola fila, igual que en el prototipo.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _IndicatorItem(
                        icon: Icons.savings,
                        title: 'Ahorro\ntotal',
                        value: CurrencyFormatter.format(totalSavings),
                        color: AppColors.primary,
                        isMobile: isMobile,
                      ),
                    ),

                    // Separador entre indicadores.
                    _IndicatorDivider(isMobile: isMobile),

                    Expanded(
                      child: _IndicatorItem(
                        icon: Icons.track_changes,
                        title: 'Metas\nactivas',
                        value: activeGoals.toString(),
                        color: AppColors.primary,
                        isMobile: isMobile,
                      ),
                    ),

                    // Separador entre indicadores.
                    _IndicatorDivider(isMobile: isMobile),

                    Expanded(
                      child: _IndicatorItem(
                        icon: Icons.bar_chart,
                        title: 'Progreso\ntotal',
                        value: '$totalProgress%',
                        color: AppColors.primary,
                        isMobile: isMobile,
                      ),
                    ),

                    // Separador entre indicadores.
                    _IndicatorDivider(isMobile: isMobile),

                    Expanded(
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

                const SizedBox(height: 10),

                const Divider(height: 1),

                const SizedBox(height: 10),

                // ============================================
                // Mensaje de estado
                // ============================================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono del mensaje informativo.
                    CircleAvatar(
                      radius: isMobile ? 14 : 15,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Icon(
                        Icons.insights,
                        size: isMobile ? 16 : 17,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Título y descripción del mensaje.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            messageTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 13 : 14,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            message,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: isMobile ? 12 : 13,
                            ),
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

/// Separador vertical utilizado entre los indicadores
/// principales del resumen.
class _IndicatorDivider extends StatelessWidget {
  const _IndicatorDivider({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: isMobile ? 82 : 90,
      color: Colors.grey.withValues(alpha: 0.25),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icono del indicador.
        CircleAvatar(
          radius: isMobile ? 24 : 20,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: isMobile ? 24 : 22),
        ),

        const SizedBox(height: 6),

        // Nombre del indicador.
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: isMobile ? 12 : 14),
        ),

        const SizedBox(height: 3),

        // Valor calculado del indicador.
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ],
    );
  }
}
