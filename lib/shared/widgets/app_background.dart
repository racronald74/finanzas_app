import 'package:flutter/material.dart';

/// Fondo reutilizable para las pantallas principales de la aplicación.
///
/// Permite mantener una apariencia visual uniforme utilizando
/// el fondo corporativo de FinanzasApp.
class AppBackground extends StatelessWidget {
  /// Contenido que se mostrará sobre el fondo.
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/fondo_splash.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
