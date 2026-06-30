import 'package:flutter/material.dart';

import '../../../data/models/expense_model.dart';

/// Tarjeta que representa un gasto.
///
/// Será utilizada por ExpensesScreen para mostrar
/// cada registro almacenado en SQLite.
class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
  });

  /// Información del gasto.
  final ExpenseModel expense;

  /// Acción que se ejecuta al presionar el botón editar.
  final VoidCallback? onEdit;

  /// Acción para eliminar el gasto.
  final VoidCallback? onDelete;

  /// Formatea una fecha ISO a dd/MM/yyyy.
  String _formatDate(String fecha) {
    final date = DateTime.parse(fecha);

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(child: Icon(Icons.shopping_cart)),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  if (expense.descripcion.trim().isNotEmpty)
                    Text(expense.descripcion)
                  else
                    const Text(
                      'Sin descripción',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),

                  const SizedBox(height: 6),

                  Text(
                    _formatDate(expense.fecha),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '\$${expense.monto.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar gasto',
                      onPressed: onEdit,
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Eliminar gasto',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
