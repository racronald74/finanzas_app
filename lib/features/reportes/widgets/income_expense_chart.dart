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
        boxShadow: [
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
          const Text(
            'Ingresos vs. gastos',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF17324D),
            ),
          ),
          const SizedBox(height: 20),

          // Adapta la distribución según el ancho disponible.
          LayoutBuilder(
            builder: (context, constraints) {
              final chart = _buildVerticalChart(maxValue);

              final savings = _buildSavingsPanel(saldo, porcentajeAhorro);

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
  Widget _buildVerticalChart(double maxValue) {
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
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF60758A),
                  ),
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
                                height: 1,
                                color: const Color(0xFFE1E7EF),
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
                                  color: const Color(0xFF16A765),
                                ),
                                _buildBar(
                                  title: 'Gastos',
                                  amount: totalGastos,
                                  maxValue: scaleMax,
                                  color: const Color(0xFFE05252),
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Ingresos',
                      style: TextStyle(fontSize: 12, color: Color(0xFF355C7D)),
                    ),
                    Text(
                      'Gastos',
                      style: TextStyle(fontSize: 12, color: Color(0xFF355C7D)),
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
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17324D),
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
  Widget _buildSavingsPanel(double saldo, double percentage) {
    final savingsColor = saldo >= 0
        ? const Color(0xFF16A765)
        : const Color(0xFFE05252);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ahorro del período',
            style: TextStyle(fontSize: 14, color: Color(0xFF355C7D)),
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF355C7D)),
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
