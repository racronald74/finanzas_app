import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

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
            CustomTextField(controller: _correoController, label: 'Correo'),

            const SizedBox(height: 16),

            // Campo contraseña
            CustomTextField(
              controller: _contrasenaController,
              label: 'Contraseña',
              obscureText: true,
            ),

            const SizedBox(height: 24),

            // Botón registrar
            CustomButton(
              text: 'Registrarse',

              onPressed: () async {
                await authProvider.registerUser(
                  nombre: _nombreController.text,
                  correo: _correoController.text,
                  contrasena: _contrasenaController.text,
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(authProvider.message)));

                if (authProvider.message ==
                    'Usuario registrado correctamente') {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El correo ya está registrado'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // Navegar a Login
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
