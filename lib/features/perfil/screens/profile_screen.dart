import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

// Pantalla de perfil que permite a los usuarios ver y actualizar su información personal,
// incluyendo nombre, correo electrónico y contraseña.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).currentUser;

      if (user == null) return;

      _nombreController.text = user.nombre;
      _correoController.text = user.correo;
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.account_circle, size: 100),
            const SizedBox(height: 30),
            CustomTextField(controller: _nombreController, label: 'Nombre'),
            const SizedBox(height: 16),
            CustomTextField(controller: _correoController, label: 'Correo'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              label: 'Nueva contrasena',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: authProvider.isLoading ? 'Guardando...' : 'Guardar cambios',
              onPressed: authProvider.isLoading ? null : _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    var success = await authProvider.updateProfile(
      nombre: _nombreController.text,
      correo: _correoController.text,
    );

    if (success && _passwordController.text.trim().isNotEmpty) {
      success = await authProvider.updatePassword(_passwordController.text);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Perfil actualizado'
              : 'Revise los datos ingresados; la contrasena requiere 8 caracteres',
        ),
      ),
    );

    if (success) {
      _passwordController.clear();
    }
  }
}
