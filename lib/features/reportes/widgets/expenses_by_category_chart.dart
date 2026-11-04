import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/report_model.dart';

/// Gráfico circular de gastos agrupados por categoría.
class ExpensesByCategoryChart extends StatelessWidget {
  final List<ReportCategoryModel> categories;

  const ExpensesByCategoryChart({super.key, required this.categories});

  // Colores utilizados para identificar las categorías.
  static const List<Color> _chartColors = [
    Color(0xFF4285F4),
    Color(0xFFFF9800),
    Color(0xFF8BC34A),
    Color(0xFF9C51E0),
    Color(0xFFFFCA28),
    Color(0xFF9EABB9),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
  ];

  @override
  Widget build(BuildContext context) {
    // Ordena las categorías de mayor a menor gasto.
    final sortedCategories =
        categories.where((category) => category.totalGastos > 0).toList()
          ..sort((a, b) => b.totalGastos.compareTo(a.totalGastos));

    // Calcula el total de gastos.
    final totalGastos = sortedCategories.fold<double>(
      0,
      (total, category) => total + category.totalGastos,
    );

    // Formato numérico colombiano sin símbolo monetario.
    final numberFormat = NumberFormat.decimalPattern('es_CO');

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gastos por categoría',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17324D),
              ),
            ),
            const SizedBox(height: 20),

            // Mensaje cuando no existen gastos.
            if (sortedCategories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No hay gastos registrados en este período.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  // En pantallas amplias se muestran el gráfico
                  // y la leyenda uno al lado del otro.
                  if (constraints.maxWidth >= 600) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildDonut(
                            sortedCategories,
                            totalGastos,
                            numberFormat,
                          ),
                        ),
                        Expanded(
                          child: _buildLegend(
                            sortedCategories,
                            totalGastos,
                            numberFormat,
                          ),
                        ),
                      ],
                    );
                  }

                  // En celulares se muestra el gráfico arriba
                  // y la información de categorías debajo.
                  return Column(
                    children: [
                      _buildDonut(sortedCategories, totalGastos, numberFormat),
                      const SizedBox(height: 12),
                      _buildLegend(sortedCategories, totalGastos, numberFormat),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Construye el gráfico circular tipo dona.
  Widget _buildDonut(
    List<ReportCategoryModel> categories,
    double total,
    NumberFormat numberFormat,
  ) {
    return SizedBox(
      height: 210,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dibuja las porciones del gráfico.
            CustomPaint(
              size: const Size(190, 190),
              painter: _DonutChartPainter(
                values: categories
                    .map((category) => category.totalGastos)
                    .toList(),
                colors: List.generate(
                  categories.length,
                  (index) => _chartColors[index % _chartColors.length],
                ),
              ),
            ),

            // Información central del gráfico.
            SizedBox(
              width: 110,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$ ${numberFormat.format(total)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17324D),
                      ),
                    ),
                  ),
                  const Text(
                    'Gastos',
                    style: TextStyle(fontSize: 13, color: Color(0xFF455468)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la leyenda con los valores de cada categoría.
  Widget _buildLegend(
    List<ReportCategoryModel> categories,
    double total,
    NumberFormat numberFormat,
  ) {
    return Column(
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;

        // Calcula el porcentaje de participación.
        final percentage = category.totalGastos / total * 100;

        final color = _chartColors[index % _chartColors.length];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  // Indicador de color de la categoría.
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nombre de la categoría.
                  Expanded(
                    flex: 4,
                    child: Text(
                      category.nombreCategoria,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF26364A),
                      ),
                    ),
                  ),

                  // Porcentaje de participación.
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF455468),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Valor monetario con el símbolo al principio.
                  Expanded(
                    flex: 3,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '\$ ${numberFormat.format(category.totalGastos)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF17324D),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Línea divisoria entre categorías.
            if (index < categories.length - 1)
              const Divider(
                height: 1,
                thickness: 0.7,
                color: Color(0xFFE1E6ED),
              ),
          ],
        );
      }).toList(),
    );
  }
}

/// Pintor personalizado para dibujar el gráfico de dona.
class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, value) => sum + value);

    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);

    // Define el grosor y el tamaño del gráfico.
    final rect = Rect.fromCircle(center: center, radius: size.width / 2 - 5);

    const strokeWidth = 30.0;
    double startAngle = -math.pi / 2;

    // Dibuja cada categoría como una porción circular.
    for (int i = 0; i < values.length; i++) {
      final sweepAngle = values[i] / total * 2 * math.pi;

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}
