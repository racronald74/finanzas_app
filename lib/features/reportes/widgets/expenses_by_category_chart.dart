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
    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    // Define los colores de los textos según el tema.
    final Color textColor = highContrast
        ? Colors.black
        : const Color(0xFF17324D);
    final Color secondaryColor = highContrast
        ? Colors.black
        : const Color(0xFF455468);

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
      elevation: highContrast ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highContrast
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gastos por categoría',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),

            // Mensaje cuando no existen gastos.
            if (sortedCategories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No hay gastos registrados en este período.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryColor),
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
                            highContrast,
                            textColor,
                            secondaryColor,
                          ),
                        ),
                        Expanded(
                          child: _buildLegend(
                            sortedCategories,
                            totalGastos,
                            numberFormat,
                            highContrast,
                            textColor,
                            secondaryColor,
                          ),
                        ),
                      ],
                    );
                  }

                  // En celulares se muestra el gráfico arriba
                  // y la información de categorías debajo.
                  return Column(
                    children: [
                      _buildDonut(
                        sortedCategories,
                        totalGastos,
                        numberFormat,
                        highContrast,
                        textColor,
                        secondaryColor,
                      ),
                      const SizedBox(height: 12),
                      _buildLegend(
                        sortedCategories,
                        totalGastos,
                        numberFormat,
                        highContrast,
                        textColor,
                        secondaryColor,
                      ),
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
    bool highContrast,
    Color textColor,
    Color secondaryColor,
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
                highContrast: highContrast,
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
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    'Gastos',
                    style: TextStyle(fontSize: 13, color: secondaryColor),
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
    bool highContrast,
    Color textColor,
    Color secondaryColor,
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
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: highContrast ? Colors.white : color,
                      shape: BoxShape.circle,
                      border: highContrast
                          ? Border.all(color: Colors.black, width: 1.5)
                          : null,
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
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                  ),

                  // Porcentaje de participación.
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 12, color: secondaryColor),
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Línea divisoria entre categorías.
            if (index < categories.length - 1)
              Divider(
                height: 1,
                thickness: highContrast ? 1.5 : 0.7,
                color: highContrast ? Colors.black : const Color(0xFFE1E6ED),
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
  final bool highContrast;

  _DonutChartPainter({
    required this.values,
    required this.colors,
    required this.highContrast,
  });

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

      // En alto contraste agrega separadores negros entre segmentos.
      if (highContrast) {
        final separatorPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final separatorAngle = startAngle + sweepAngle;

        final startPoint = Offset(
          center.dx + (rect.width / 2) * math.cos(separatorAngle),
          center.dy + (rect.height / 2) * math.sin(separatorAngle),
        );

        canvas.drawLine(center, startPoint, separatorPaint);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.highContrast != highContrast;
  }
}
