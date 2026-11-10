import 'package:flutter/material.dart';

/// Tarjeta compacta para mostrar el resumen financiero.
class ReportSummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const ReportSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    // Define los colores según el tema activo.
    final Color cardColor = highContrast ? Colors.white : backgroundColor;
    final Color textColor = highContrast
        ? Colors.black
        : const Color(0xFF455468);
    final Color valueColor = highContrast ? Colors.black : color;
    final Color iconColor = highContrast ? Colors.black : color;

    return Container(
      // La altura se adapta al contenido.
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        // Conserva los fondos originales en modo normal.
        color: cardColor,
        borderRadius: BorderRadius.circular(10),

        // Refuerza el borde en alto contraste.
        border: Border.all(
          color: highContrast ? Colors.black : color.withValues(alpha: 0.35),
          width: highContrast ? 2 : 1,
        ),

        // Mantiene la sombra únicamente en el tema normal.
        boxShadow: highContrast
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Círculo del icono.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: highContrast
                  ? Colors.white
                  : color.withValues(alpha: 0.20),
              shape: BoxShape.circle,
              border: highContrast
                  ? Border.all(color: Colors.black, width: 1.5)
                  : null,
            ),
            child: Icon(icon, size: 21, color: iconColor),
          ),

          const SizedBox(width: 9),

          // Título y valor monetario.
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),

                // Reduce el tamaño del monto si no cabe.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
