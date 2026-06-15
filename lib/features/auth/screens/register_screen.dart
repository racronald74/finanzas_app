import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores de los campos de texto
  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _correoController = TextEditingController();

  final TextEditingController _contrasenaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Acceso al Provider
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // Campo nombre
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),

            const SizedBox(height: 16),

            // Campo correo
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),

            const SizedBox(height: 16),

            // Campo contraseña
            TextField(
              controller: _contrasenaController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),

            const SizedBox(height: 24),

            // Botón registrar
            ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () async {
                      await authProvider.registerUser(
                        nombre: _nombreController.text,
                        correo: _correoController.text,
                        contrasena: _contrasenaController.text,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authProvider.message)),
                        );
                      }
                    },

              child: authProvider.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}
