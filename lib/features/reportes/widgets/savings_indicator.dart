import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Indicador visual del porcentaje de ahorro del período.
class SavingsIndicator extends StatelessWidget {
  final double totalIngresos;
  final double saldo;

  const SavingsIndicator({
    super.key,
    required this.totalIngresos,
    required this.saldo,
  });

  @override
  Widget build(BuildContext context) {
    // Calcula el porcentaje de ahorro evitando dividir entre cero.
    final double savingsPercentage = totalIngresos > 0
        ? (saldo / totalIngresos) * 100
        : 0;

    // Limita el valor visual de la barra entre 0 y 1.
    final double progress = (savingsPercentage / 100).clamp(0.0, 1.0);

    // Muestra el porcentaje con dos decimales.
    final percentageFormat = NumberFormat('##0.00', 'es_CO');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Porcentaje de ahorro',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17324D),
              ),
            ),
            const SizedBox(height: 16),

            // Muestra el porcentaje calculado.
            Center(
              child: Text(
                '${percentageFormat.format(savingsPercentage)} %',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A765),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Representa visualmente la proporción de ahorro.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF16A765),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Porcentaje de ingresos que queda disponible '
              'después de cubrir los gastos.',
              style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }
}
