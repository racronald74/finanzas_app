import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Gráfica comparativa de ingresos y gastos.
class IncomeExpenseChart extends StatelessWidget {
  final double totalIngresos;
  final double totalGastos;

  const IncomeExpenseChart({
    super.key,
    required this.totalIngresos,
    required this.totalGastos,
  });

  // Formato monetario colombiano con el símbolo al principio.
  String _formatCurrency(double amount) {
    return '\$ ${NumberFormat.decimalPattern('es_CO').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    // Define los colores según el tema activo.
    final Color textColor = highContrast
        ? Colors.black
        : const Color(0xFF17324D);
    final Color secondaryColor = highContrast
        ? Colors.black
        : const Color(0xFF60758A);

    // Calcula el saldo y el porcentaje de ahorro.
    final saldo = totalIngresos - totalGastos;
    final porcentajeAhorro = totalIngresos > 0
        ? (saldo / totalIngresos) * 100
        : 0.0;

    // Obtiene el valor máximo de las columnas.
    final maxValue = totalIngresos > totalGastos ? totalIngresos : totalGastos;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: highContrast ? Border.all(color: Colors.black, width: 2) : null,
        boxShadow: highContrast
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresos vs. gastos',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),

          // Adapta la distribución según el ancho disponible.
          LayoutBuilder(
            builder: (context, constraints) {
              final chart = _buildVerticalChart(
                maxValue,
                highContrast,
                textColor,
                secondaryColor,
              );

              final savings = _buildSavingsPanel(
                saldo,
                porcentajeAhorro,
                highContrast,
                textColor,
              );

              // En pantallas amplias, el ahorro aparece al lado.
              if (constraints.maxWidth >= 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: chart),
                    const SizedBox(width: 20),
                    SizedBox(width: 180, child: savings),
                  ],
                );
              }

              // En móviles, el ahorro aparece debajo del gráfico.
              return Column(
                children: [chart, const SizedBox(height: 18), savings],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Construye el gráfico con columnas y escala vertical.
  Widget _buildVerticalChart(
    double maxValue,
    bool highContrast,
    Color textColor,
    Color secondaryColor,
  ) {
    // Evita divisiones por cero y establece una escala visible.
    final scaleMax = maxValue > 0 ? maxValue : 1.0;

    // Genera los valores de referencia del eje vertical.
    final scaleValues = List.generate(5, (index) => scaleMax * (4 - index) / 4);

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Valores monetarios del eje vertical.
          SizedBox(
            width: 48,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: scaleValues.map((value) {
                return Text(
                  _formatAxisValue(value),
                  style: TextStyle(fontSize: 10, color: secondaryColor),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),

          // Área de columnas y líneas de referencia.
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // Líneas horizontales de referencia.
                          ...List.generate(5, (index) {
                            final top = constraints.maxHeight * index / 4;

                            return Positioned(
                              top: top,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: highContrast ? 1.5 : 1,
                                color: highContrast
                                    ? Colors.black
                                    : const Color(0xFFE1E7EF),
                              ),
                            );
                          }),

                          // Columnas verticales.
                          Positioned.fill(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBar(
                                  title: 'Ingresos',
                                  amount: totalIngresos,
                                  maxValue: scaleMax,
                                  color: highContrast
                                      ? const Color(0xFF003B8E)
                                      : const Color(0xFF16A765),
                                  highContrast: highContrast,
                                  textColor: textColor,
                                ),
                                _buildBar(
                                  title: 'Gastos',
                                  amount: totalGastos,
                                  maxValue: scaleMax,
                                  color: highContrast
                                      ? Colors.black
                                      : const Color(0xFFE05252),
                                  highContrast: highContrast,
                                  textColor: textColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Ingresos',
                      style: TextStyle(fontSize: 12, color: secondaryColor),
                    ),
                    Text(
                      'Gastos',
                      style: TextStyle(fontSize: 12, color: secondaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una columna proporcional al valor máximo.
  Widget _buildBar({
    required String title,
    required double amount,
    required double maxValue,
    required Color color,
    required bool highContrast,
    required Color textColor,
  }) {
    final percentage = (amount / maxValue).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Valor monetario encima de la columna.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatCurrency(amount),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Altura proporcional de la columna.
          Container(
            width: 48,
            height: 135 * percentage,
            decoration: BoxDecoration(
              color: color,
              border: highContrast
                  ? Border.all(color: Colors.black, width: 1.5)
                  : null,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Panel que muestra el ahorro del período.
  Widget _buildSavingsPanel(
    double saldo,
    double percentage,
    bool highContrast,
    Color textColor,
  ) {
    final savingsColor = highContrast
        ? Colors.black
        : saldo >= 0
        ? const Color(0xFF16A765)
        : const Color(0xFFE05252);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highContrast ? Colors.white : const Color(0xFFF0F5FC),
        borderRadius: BorderRadius.circular(12),
        border: highContrast
            ? Border.all(color: Colors.black, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ahorro del período',
            style: TextStyle(fontSize: 14, color: textColor),
          ),
          const SizedBox(height: 5),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: savingsColor,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(saldo),
              style: TextStyle(fontSize: 13, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Simplifica los valores mostrados en el eje vertical.
  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} mil';
    }

    return value.toStringAsFixed(0);
  }
}
