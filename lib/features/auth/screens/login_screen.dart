import 'register_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controlador correo
  final TextEditingController _correoController = TextEditingController();

  // Controlador contraseña
  final TextEditingController _contrasenaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _contrasenaController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                final success = await authProvider.login(
                  correo: _correoController.text,
                  contrasena: _contrasenaController.text,
                );

                if (!context.mounted) return;

                if (success) {
                  Navigator.pushReplacement(
                    context,

                    MaterialPageRoute(
                      builder: (_) => DashboardScreen(
                        nombreUsuario: authProvider.currentUser?.nombre ?? '',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Correo o contraseña incorrectos'),
                    ),
                  );
                }
              },

              child: const Text('Iniciar sesión'),
            ),
            const SizedBox(height: 16),

            // Navegar a Registro
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },

              child: const Text('¿No tienes cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }
}
