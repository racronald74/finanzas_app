import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../auth/screens/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String nombreUsuario;

  const DashboardScreen({super.key, required this.nombreUsuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(Icons.account_circle, size: 100),

            const SizedBox(height: 20),

            Text(
              'Bienvenido $nombreUsuario',
              style: const TextStyle(fontSize: 24),
            ),

            const SizedBox(height: 30),

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
          ],
        ),
      ),
    );
  }
}
