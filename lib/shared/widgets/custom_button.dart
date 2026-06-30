import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// Botón principal reutilizable de la aplicación.
///
/// Se utiliza en todos los formularios para ejecutar la
/// acción principal, por ejemplo:
///
/// - Iniciar sesión.
/// - Registrarse.
/// - Crear ingreso.
/// - Registrar gasto.
/// - Crear meta.
/// - Guardar cambios.
class CustomButton extends StatelessWidget {
  /// Texto mostrado en el botón.
  final String text;

  /// Acción ejecutada al presionar el botón.
  final VoidCallback? onPressed;

  /// Indica si debe mostrarse el indicador de carga.
  final bool isLoading;

  /// Icono opcional mostrado antes del texto.
  final IconData? icon;

  /// Color de fondo del botón.
  final Color? backgroundColor;

  /// Color del texto e icono.
  final Color? foregroundColor;

  /// Altura del botón.
  final double height;

  /// Radio de las esquinas.
  final double borderRadius;

  /// Constructor del botón reutilizable.
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 52,
    this.borderRadius = 14,
  });

  /// Construye el botón.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),

        // Mientras se ejecuta una acción se muestra
        // un indicador de carga.
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            // Contenido normal del botón.
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // El icono solo se muestra cuando se envía.
                  if (icon != null) ...[
                    Icon(icon, size: 22),
                    const SizedBox(width: 10),
                  ],

                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
