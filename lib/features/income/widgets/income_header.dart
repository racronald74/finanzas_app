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
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Color(0xFF3F6DB5)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onAvatarPressed,
                child: const CircleAvatar(
                  radius: 22,
                  child: Icon(Icons.person, size: 26),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Ingresos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      periodText,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),

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
      ),
    );
  }
}
