import 'package:flutter/material.dart';

/// Widget que muestra el resumen financiero del módulo
/// de gastos.
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Expanded(
          child: SizedBox(
            height: 190,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('Total gastado'),

                    const SizedBox(height: 8),

                    Text(
                      '\$${totalGastado.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Presupuesto usado',
                      style: TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${(usedPercentage * 100).round()}% de \$${totalIncome.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 7),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: usedPercentage,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),
        // Muestra el presupuesto disponible y un indicador
        Expanded(
          child: SizedBox(
            height: 190,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                  children: [
                    const Text('Disponible'),

                    const SizedBox(height: 8),

                    Text(
                      '\$${disponible.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Presupuesto disponible',
                      style: TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${(availablePercentage * 100).round()}% de \$${totalIncome.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 7),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: availablePercentage,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
