import 'package:flutter/material.dart';

/// Encabezado específico del módulo de Ingresos.
///
/// Permite mostrar:
/// - Avatar del usuario.
/// - Título del módulo.
/// - Período seleccionado.
/// - Botón para seleccionar el período.
class IncomeHeader extends StatelessWidget {
  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  /// Acción ejecutada al pulsar el calendario.
  final VoidCallback? onCalendarPressed;

  /// Texto que representa el período seleccionado.
  final String periodText;

  const IncomeHeader({
    super.key,
    this.onAvatarPressed,
    this.onCalendarPressed,

    /// Valor utilizado mientras todavía no se conecta
    /// el selector de período.
    this.periodText = 'Mes actual - Febrero 2026',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Altura del encabezado para mantener
      // consistencia visual con los demás módulos.
      height: 150,

      padding: const EdgeInsets.symmetric(horizontal: 20),

      decoration: const BoxDecoration(color: Color(0xFF3F6DB5)),

      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ============================================
            // Avatar del usuario
            // ============================================
            GestureDetector(
              onTap: onAvatarPressed,
              child: const CircleAvatar(
                radius: 22,
                child: Icon(Icons.person, size: 26),
              ),
            ),

            const SizedBox(width: 16),

            // ============================================
            // Título y período
            // ============================================
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título del módulo.
                  const Text(
                    'Ingresos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Período actualmente seleccionado.
                  Text(
                    periodText,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

            // ============================================
            // Botón de calendario
            // ============================================
            IconButton(
              onPressed: onCalendarPressed,
              icon: const Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
