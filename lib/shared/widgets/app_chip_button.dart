import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// Botón reutilizable con estilo tipo "chip".
///
/// Se utiliza para acciones secundarias dentro de tarjetas,
/// por ejemplo:
///
/// - Ver detalle.
/// - Aportar.
/// - Editar.
/// - Cancelar.
///
/// No reemplaza al [CustomButton], ya que este componente
/// está pensado para acciones pequeñas dentro de un Card.
class AppChipButton extends StatelessWidget {
  /// Texto mostrado en el botón.
  final String text;

  /// Acción ejecutada al presionar.
  final VoidCallback? onPressed;

  /// Icono opcional.
  final IconData? icon;

  /// Indica si debe mostrarse con el estilo principal.
  final bool isPrimary;

  /// Constructor del botón tipo chip.
  const AppChipButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
  });

  /// Construye el botón.
  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isPrimary ? AppColors.primary : Colors.white;

    final Color foregroundColor = isPrimary ? Colors.white : AppColors.primary;

    final Color borderColor = AppColors.primary;

    return OutlinedButton.icon(
      onPressed: onPressed,

      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),

      label: Text(text),

      style: OutlinedButton.styleFrom(
        elevation: 0,

        backgroundColor: backgroundColor,

        foregroundColor: foregroundColor,

        side: BorderSide(color: borderColor),

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),

        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
