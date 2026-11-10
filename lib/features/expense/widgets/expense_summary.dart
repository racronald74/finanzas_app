import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que muestra el resumen financiero del módulo de gastos.
///
/// Muestra:
/// - Total gastado.
/// - Disponible restante.
class ExpenseSummary extends StatelessWidget {
  const ExpenseSummary({
    super.key,
    required this.totalGastado,
    required this.disponible,
    required this.usedPercentage,
    required this.totalIncome,
    required this.availablePercentage,
  });

  final double totalGastado;
  final double disponible;
  final double usedPercentage;
  final double totalIncome;
  final double availablePercentage;

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
        : Colors.grey.shade700;

    final Color progressColor = highContrast
        ? const Color(0xFF003B8E)
        : Colors.red;

    final Color availableColor = highContrast
        ? const Color(0xFF003B8E)
        : Colors.green;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            color: Colors.white,
            elevation: highContrast ? 0 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: highContrast
                  ? const BorderSide(color: Colors.black, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Total gastado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatCurrency(totalGastado),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: highContrast ? Colors.black : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${(usedPercentage * 100).round()}% de ${_formatCurrency(totalIncome)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: secondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: usedPercentage,
                      minHeight: 10,
                      backgroundColor: highContrast
                          ? Colors.white
                          : Colors.grey.shade300,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Muestra el presupuesto disponible y su indicador.
        Expanded(
          child: Card(
            color: Colors.white,
            elevation: highContrast ? 0 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: highContrast
                  ? const BorderSide(color: Colors.black, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Disponible',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatCurrency(disponible),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: highContrast ? Colors.black : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${(availablePercentage * 100).round()}% de ${_formatCurrency(totalIncome)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: secondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: availablePercentage,
                      minHeight: 10,
                      backgroundColor: highContrast
                          ? Colors.white
                          : Colors.grey.shade300,
                      color: availableColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Formatea valores monetarios con separador de miles
  /// y coloca el símbolo de moneda antes del valor.
  String _formatCurrency(double value) {
    final formatted = NumberFormat('#,##0', 'es_CO').format(value);

    return '\$$formatted';
  }
}
