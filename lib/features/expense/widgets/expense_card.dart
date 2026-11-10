import 'package:flutter/material.dart';

import '../../../data/models/expense_model.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Tarjeta que representa un gasto.
///
/// Será utilizada por ExpensesScreen para mostrar
/// cada registro almacenado en SQLite.
class ExpenseCard extends StatelessWidget {
  /// Formatea valores monetarios con separador de miles.
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
    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    // Determina si el gasto fue generado por una obligación.
    final bool esObligacion =
        expense.origen.toUpperCase() == 'OBLIGACION' ||
        expense.origen.toUpperCase() == 'OBLIGACIÓN';

    // Define los colores según el tema.
    final Color textColor = highContrast
        ? Colors.black
        : const Color(0xFF17324D);

    final Color secondaryColor = highContrast ? Colors.black : Colors.grey;

    final Color primaryColor = highContrast
        ? const Color(0xFF003B8E)
        : Colors.blue;

    return Card(
      color: Colors.white,
      elevation: highContrast ? 0 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highContrast
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          // Centra verticalmente el icono y el contenido.
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: highContrast ? Colors.white : null,
              child: Icon(Iconsax.shopping_cart, size: 26, color: primaryColor),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),

                  if (expense.descripcion.trim().isNotEmpty)
                    Text(
                      expense.descripcion,
                      style: TextStyle(color: textColor),
                    )
                  else
                    Text(
                      'Sin descripción',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: secondaryColor,
                      ),
                    ),

                  const SizedBox(height: 6),

                  Text(
                    _formatDate(expense.fecha),
                    style: TextStyle(color: secondaryColor),
                  ),
                  const SizedBox(height: 4),

                  // Muestra el origen desde el cual se generó el gasto.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: highContrast
                          ? Colors.white
                          : _getOrigenBackgroundColor(expense.origen),
                      borderRadius: BorderRadius.circular(8),
                      border: highContrast
                          ? Border.all(color: Colors.black, width: 1.5)
                          : null,
                    ),
                    child: Text(
                      expense.origen,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: highContrast
                            ? Colors.black
                            : _getOrigenTextColor(expense.origen),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 8),

                if (!esObligacion)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón para editar el gasto.
                      IconButton(
                        icon: Icon(Iconsax.edit, size: 28, color: primaryColor),
                        tooltip: 'Editar gasto',
                        onPressed: onEdit,
                      ),

                      // Botón para eliminar el gasto.
                      IconButton(
                        icon: Icon(
                          Iconsax.trash,
                          size: 26,
                          color: highContrast ? Colors.black : Colors.red,
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
