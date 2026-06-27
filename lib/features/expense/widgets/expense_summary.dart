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
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total gastado'),

                  const SizedBox(height: 8),

                  Text(
                    '\$${totalGastado.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),

                  const SizedBox(height: 12),

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

        const SizedBox(width: 12),
        // Muestra el presupuesto disponible y un indicador circular
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Center(child: Text('Disponible restante')),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      '\$${disponible.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 7,
                          color: Colors.grey.shade300,
                        ),

                        CircularProgressIndicator(
                          value: availablePercentage,
                          strokeWidth: 7,
                          color: Colors.green,
                          backgroundColor: Colors.transparent,
                        ),

                        Text(
                          '${(availablePercentage * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 2),

                  const Text(
                    'del presupuesto',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
