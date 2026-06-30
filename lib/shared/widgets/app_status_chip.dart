import 'package:flutter/material.dart';

/// Etiqueta reutilizable para mostrar el estado de un registro.
///
/// Se utiliza para representar visualmente estados como:
///
/// - Activa.
/// - Completada.
/// - Pendiente.
/// - Vencida.
///
/// El color del fondo y del texto puede personalizarse
/// según el estado que se desee representar.
class AppStatusChip extends StatelessWidget {
  /// Texto que identifica el estado.
  final String text;

  /// Color principal del estado.
  final Color color;

  /// Constructor del componente.
  const AppStatusChip({super.key, required this.text, required this.color});

  /// Construye la etiqueta de estado.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
