import 'package:flutter/material.dart';

import '../../../data/models/expense_model.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Tarjeta que representa un gasto.
///
/// Será utilizada por ExpensesScreen para mostrar
/// cada registro almacenado en SQLite.
class ExpenseCard extends StatelessWidget {
  /// Formatea valores monetarios con separador de miles
  /// y coloca el símbolo de moneda antes del valor.
  String _formatCurrency(double value) {
    final formatted = NumberFormat('#,##0', 'es_CO').format(value);

    return '\$$formatted';
  }

  /// Constructor de la tarjeta de gasto.
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

  /// Obtiene el color de fondo según el origen del gasto.
  Color _getOrigenBackgroundColor(String origen) {
    switch (origen.toUpperCase()) {
      case 'MANUAL':
        return Colors.blue.shade100;

      case 'AUTOMÁTICO':
      case 'AUTOMATICO':
        return Colors.orange.shade100;

      case 'OBLIGACIÓN':
      case 'OBLIGACION':
        return Colors.green.shade100;

      case 'DEUDA':
        return Colors.purple.shade100;

      default:
        return Colors.grey.shade200;
    }
  }

  /// Obtiene el color del texto según el origen del gasto.
  Color _getOrigenTextColor(String origen) {
    switch (origen.toUpperCase()) {
      case 'MANUAL':
        return Colors.blue.shade700;

      case 'AUTOMÁTICO':
      case 'AUTOMATICO':
        return Colors.orange.shade700;

      case 'OBLIGACIÓN':
      case 'OBLIGACION':
        return Colors.green.shade700;

      case 'DEUDA':
        return Colors.purple.shade700;

      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esObligacion =
        expense.origen.toUpperCase() == 'OBLIGACION' ||
        expense.origen.toUpperCase() == 'OBLIGACIÓN';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          // Centra verticalmente el icono y el contenido de la tarjeta.
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 26,
              child: Icon(Iconsax.shopping_cart, size: 26, color: Colors.blue),
            ),

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
                  const SizedBox(height: 4),

                  // Muestra el origen desde el cual se generó el gasto.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getOrigenBackgroundColor(expense.origen),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      expense.origen,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getOrigenTextColor(expense.origen),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formatCurrency(expense.monto),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 8),

                if (!esObligacion)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón para editar el gasto.
                      IconButton(
                        icon: const Icon(Iconsax.edit, size: 28),
                        tooltip: 'Editar gasto',
                        onPressed: onEdit,
                      ),

                      // Botón para eliminar el gasto.
                      IconButton(
                        icon: const Icon(
                          Iconsax.trash,
                          size: 26,
                          color: Colors.red,
                        ),
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
