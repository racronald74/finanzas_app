import 'package:flutter/material.dart';
import 'drawer_menu_item.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';

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

    return Drawer(
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
                  CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),

                  SizedBox(height: 12),

                  Text(
                    usuario?.nombre ?? 'Usuario',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    usuario?.correo ?? '',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 12),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Cuenta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  DrawerMenuItem(
                    icon: Icons.person_outline,
                    title: 'Datos personales',
                    onTap: () {},
                  ),

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

                  DrawerMenuItem(
                    icon: Icons.accessibility_new,
                    title: 'Accesibilidad',
                    onTap: () {},
                  ),

                  const Divider(),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Soporte',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  DrawerMenuItem(
                    icon: Icons.help_outline,
                    title: 'Ayuda y soporte',
                    onTap: () {},
                  ),

                  DrawerMenuItem(
                    icon: Icons.info_outline,
                    title: 'Acerca de la app',
                    onTap: () {},
                  ),

                  const Divider(),

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
