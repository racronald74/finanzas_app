import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _resetCorreoController = TextEditingController();
  final TextEditingController _resetContrasenaController =
      TextEditingController();

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    _resetCorreoController.dispose();
    _resetContrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(controller: _correoController, label: 'Correo'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _contrasenaController,
              label: 'Contrasena',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: authProvider.isLoading ? 'Ingresando...' : 'Iniciar sesion',
              onPressed: authProvider.isLoading ? null : _login,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _showResetPasswordDialog,
              child: const Text('Olvide mi contrasena'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('No tienes cuenta? Registrate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .login(
          correo: _correoController.text,
          contrasena: _contrasenaController.text,
        );

    if (!mounted) return;

    if (success) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            nombreUsuario: authProvider.currentUser?.nombre ?? '',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Correo o contrasena incorrectos')),
    );
  }

  Future<void> _showResetPasswordDialog() async {
    _resetCorreoController.text = _correoController.text.trim();
    _resetContrasenaController.clear();

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperar contrasena'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _resetCorreoController,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _resetContrasenaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contrasena',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true) return;
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.resetPassword(
      correo: _resetCorreoController.text,
      nuevaContrasena: _resetContrasenaController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(authProvider.message)));

    if (authProvider.message == 'Contrasena actualizada correctamente') {
      _correoController.text = _resetCorreoController.text.trim();
      _contrasenaController.text = _resetContrasenaController.text.trim();
    }
  }
}
