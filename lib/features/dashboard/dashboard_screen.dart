import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../auth/screens/login_screen.dart';
import '../perfil/screens/profile_screen.dart';
import '../../shared/widgets/custom_button.dart';
import '../income/screens/incomes_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String nombreUsuario;

  const DashboardScreen({super.key, required this.nombreUsuario});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final displayName = currentUser?.nombre ?? nombreUsuario;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          //
          children: [
            const Icon(Icons.account_circle, size: 100),

            const SizedBox(height: 20),

            Text(
              'Bienvenido $displayName',
              style: const TextStyle(fontSize: 24),
            ),

            const SizedBox(height: 20),

            // Agrega un botón para ir al perfil
            CustomButton(
              text: 'Mi Perfil',

              onPressed: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),

            const SizedBox(height: 30),

            // Agrega un botón para cerrar sesión
            ElevatedButton(
              onPressed: () {
                // Obtiene el provider
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                // Limpia la sesión
                authProvider.logout();

                // Regresa al login
                Navigator.pushAndRemoveUntil(
                  context,

                  MaterialPageRoute(builder: (_) => const LoginScreen()),

                  (route) => false,
                );
              },

              child: const Text('Cerrar sesión'),
            ),

            // Agrega un botón para ir a la pantalla de ingresos
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IncomesScreen()),
                );
              },
              child: const Text('Ingresos'),
            ),
          ],
        ),
      ),
    );
  }
}
