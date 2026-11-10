import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'drawer_menu_item.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/perfil/screens/profile_screen.dart';
import '../../features/perfil/screens/about_screen.dart';
import '../../features/perfil/screens/help_screen.dart';
import '../../features/perfil/screens/accessibility_screen.dart';

/// Drawer principal de FinanzApp.
///
/// Este componente será reutilizado desde todas
/// las pantallas de la aplicación.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtiene el usuario autenticado.
    final authProvider = context.watch<AuthProvider>();
    final usuario = authProvider.currentUser;

    // Consulta la preferencia de alto contraste.
    final highContrast = usuario?.altoContraste ?? false;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Encabezado del Drawer.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF3F6DB5),
              child: Column(
                children: [
                  // Avatar del usuario.
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: highContrast
                        ? const Color(0xFF003B8E)
                        : null,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.person, size: 34),
                  ),

                  const SizedBox(height: 12),

                  // Nombre del usuario autenticado.
                  Text(
                    usuario?.nombre ?? 'Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Correo del usuario autenticado.
                  Text(
                    usuario?.correo ?? '',
                    style: TextStyle(
                      color: highContrast ? Colors.white : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 12),

                  // Sección de opciones de cuenta.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Cuenta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: highContrast ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),

                  DrawerMenuItem(
                    icon: Icons.person_outline,
                    title: 'Datos personales',
                    onTap: () {
                      // Cierra el menú lateral antes de abrir el perfil.
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),

                  // Opciones reservadas para futuras versiones.

                  /*
                  DrawerMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Cambiar contraseña',
                    onTap: () {},
                  ),

                  DrawerMenuItem(
                    icon: Icons.language,
                    title: 'Idioma',
                    onTap: () {},
                  ),

                  DrawerMenuItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Tema',
                    onTap: () {},
                  ),
                  */
                  DrawerMenuItem(
                    icon: Icons.accessibility_new,
                    title: 'Accesibilidad',
                    onTap: () {
                      // Cierra el menú lateral antes de abrir accesibilidad.
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccessibilityScreen(),
                        ),
                      );
                    },
                  ),

                  // Separador entre las secciones.
                  Divider(
                    color: highContrast ? Colors.black : null,
                    thickness: highContrast ? 1.5 : null,
                  ),

                  // Sección de soporte.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Soporte',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: highContrast ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),

                  DrawerMenuItem(
                    icon: Icons.help_outline,
                    title: 'Ayuda y soporte',
                    onTap: () {
                      // Cierra el menú lateral antes de abrir la ayuda.
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      );
                    },
                  ),

                  DrawerMenuItem(
                    icon: Icons.info_outline,
                    title: 'Acerca de la app',
                    onTap: () {
                      // Cierra el menú lateral antes de abrir la información.
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),

                  // Separador antes de cerrar sesión.
                  Divider(
                    color: highContrast ? Colors.black : null,
                    thickness: highContrast ? 1.5 : null,
                  ),

                  DrawerMenuItem(
                    icon: Icons.logout,
                    title: 'Cerrar sesión',
                    iconColor: Colors.red,
                    onTap: () {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );

                      authProvider.logout();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
