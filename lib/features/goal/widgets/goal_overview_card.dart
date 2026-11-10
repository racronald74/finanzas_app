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

    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    // Obtiene el color principal del tema actual.
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    // Define el color secundario según el tema.
    final Color secondaryColor = highContrast
        ? Colors.black
        : AppColors.textSecondary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          // Mantiene el fondo blanco y agrega un borde en alto contraste.
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: highContrast
                ? const BorderSide(color: Colors.black, width: 2)
                : BorderSide.none,
          ),
          elevation: 2,

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
                        color: primaryColor,
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
                        color: primaryColor,
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
                        color: primaryColor,
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
                        color: primaryColor,
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Aumenta la visibilidad del separador en alto contraste.
                Divider(
                  height: 1,
                  thickness: highContrast ? 1.5 : 1,
                  color: highContrast ? Colors.black : null,
                ),

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
                      backgroundColor: primaryColor.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.insights,
                        size: isMobile ? 16 : 17,
                        color: primaryColor,
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
                              color: secondaryColor,
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
    // Detecta si está activo el alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    return Container(
      width: highContrast ? 2 : 1,
      height: isMobile ? 82 : 90,
      color: highContrast ? Colors.black : Colors.grey.withValues(alpha: 0.25),
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 13 : 16,
            ),
          ),
        ),
      ],
    );
  }
}
