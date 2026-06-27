import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

// Pantalla de registro para que los usuarios puedan crear una cuenta en la aplicación.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(controller: _nombreController, label: 'Nombre'),
            const SizedBox(height: 16),
            CustomTextField(controller: _correoController, label: 'Correo'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _contrasenaController,
              label: 'Contrasena',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: authProvider.isLoading ? 'Registrando...' : 'Registrarse',
              onPressed: authProvider.isLoading ? null : _register,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ya tienes cuenta? Inicia sesion'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.registerUser(
      nombre: _nombreController.text,
      correo: _correoController.text,
      contrasena: _contrasenaController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(authProvider.message)));

    if (authProvider.message == 'Usuario registrado correctamente') {
      Navigator.pop(context);
    }
  }
}
