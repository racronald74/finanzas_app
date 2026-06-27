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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.shopping_cart)),

        title: Text(expense.nombre),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [Text(expense.fecha), Text(expense.origen)],
        ),

        // Contenedor para el monto y los botones de acción.
        trailing: SizedBox(
          width: 120,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Text('\$${expense.monto.toStringAsFixed(0)}'),

              const SizedBox(height: 6),

              Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Editar gasto',
                    onPressed: onEdit,
                  ),

                  const SizedBox(width: 12),

                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Eliminar gasto',
                    onPressed: () {
                      onDelete?.call();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
