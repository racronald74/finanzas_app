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
    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    // Define los colores según el tema activo.
    final Color textColor = highContrast
        ? Colors.black
        : const Color(0xFF17324D);
    final Color savingsColor = highContrast
        ? Colors.black
        : const Color(0xFF16A765);

    // Calcula el porcentaje de ahorro evitando dividir entre cero.
    final double savingsPercentage = totalIngresos > 0
        ? (saldo / totalIngresos) * 100
        : 0;

    // Limita el valor visual de la barra entre 0 y 1.
    final double progress = (savingsPercentage / 100).clamp(0.0, 1.0);

    // Muestra el porcentaje con dos decimales.
    final percentageFormat = NumberFormat('##0.00', 'es_CO');

    return Card(
      color: Colors.white,
      elevation: highContrast ? 0 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
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
              'Porcentaje de ahorro',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            // Muestra el porcentaje calculado.
            Center(
              child: Text(
                '${percentageFormat.format(savingsPercentage)} %',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: savingsColor,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Representa visualmente la proporción de ahorro.
            Container(
              decoration: highContrast
                  ? BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: highContrast
                      ? Colors.white
                      : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    highContrast
                        ? const Color(0xFF003B8E)
                        : const Color(0xFF16A765),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Porcentaje de ingresos que queda disponible '
              'después de cubrir los gastos.',
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
