import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// Botón reutilizable con estilo tipo chip.
///
/// Se utiliza para acciones secundarias dentro de tarjetas.
class AppChipButton extends StatelessWidget {
  /// Texto mostrado en el botón.
  final String text;

  /// Acción ejecutada al presionar.
  final VoidCallback? onPressed;

  /// Icono opcional.
  final IconData? icon;

  /// Indica si debe mostrarse con el estilo principal.
  final bool isPrimary;

  /// Color utilizado para el estilo principal del botón.
  final Color? primaryColor;

  /// Constructor del botón tipo chip.
  const AppChipButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // Detecta si está activo el tema de alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    // Permite personalizar el color principal del botón.
    final Color buttonColor = primaryColor ?? AppColors.primary;

    // Define los colores del botón según el tema.
    final Color backgroundColor = isPrimary ? buttonColor : Colors.white;

    final Color foregroundColor = isPrimary ? Colors.white : buttonColor;

    // Define los colores para botones deshabilitados.
    final Color disabledBackgroundColor = highContrast
        ? Colors.white
        : Colors.grey.shade300;

    final Color disabledForegroundColor = highContrast
        ? Colors.black
        : Colors.grey.shade600;

    // Define el borde del botón.
    final Color borderColor = highContrast
        ? Colors.black
        : onPressed == null
        ? Colors.grey.shade300
        : buttonColor;

    return OutlinedButton.icon(
      onPressed: onPressed,

      // Muestra el icono únicamente cuando fue proporcionado.
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),

      label: Text(text),

      style: OutlinedButton.styleFrom(
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,

        // Aumenta el grosor del borde en alto contraste.
        side: BorderSide(color: borderColor, width: highContrast ? 1.5 : 1),

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),

        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),

        // Colores aplicados cuando el botón está deshabilitado.
        disabledBackgroundColor: disabledBackgroundColor,
        disabledForegroundColor: disabledForegroundColor,
      ),
    );
  }
}
