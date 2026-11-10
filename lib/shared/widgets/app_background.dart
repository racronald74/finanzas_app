import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Fondo reutilizable para las pantallas principales de la aplicación.
class AppBackground extends StatelessWidget {
  // Contenido que se mostrará sobre el fondo.
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Consulta la preferencia de alto contraste del usuario.
    final altoContraste =
        context.watch<AuthProvider>().currentUser?.altoContraste ?? false;

    return Container(
      width: double.infinity,
      height: double.infinity,

      // En alto contraste utiliza un fondo blanco sin imágenes.
      decoration: altoContraste
          ? const BoxDecoration(color: Colors.white)
          : const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondo_splash.png'),
                fit: BoxFit.cover,
              ),
            ),
      child: child,
    );
  }
}
