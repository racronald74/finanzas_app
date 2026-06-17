import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controladores de los campos
  final TextEditingController _nombreController = TextEditingController();

  final TextEditingController _correoController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Esperamos a que el widget termine de construirse
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final user = authProvider.currentUser;

      if (user != null) {
        _nombreController.text = user.nombre;

        _correoController.text = user.correo;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            const SizedBox(height: 20),

            const Icon(Icons.account_circle, size: 100),

            const SizedBox(height: 30),

            CustomTextField(controller: _nombreController, label: 'Nombre'),

            const SizedBox(height: 16),

            CustomTextField(controller: _correoController, label: 'Correo'),

            const SizedBox(height: 30),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _passwordController,
              label: 'Nueva contraseña',
              obscureText: true,
            ),

            CustomButton(
              text: 'Guardar cambios',

              onPressed: () async {
                bool success = await authProvider.updateProfile(
                  nombre: _nombreController.text,

                  correo: _correoController.text,
                );

                if (_passwordController.text.trim().isNotEmpty) {
                  success = await authProvider.updatePassword(
                    _passwordController.text,
                  );
                }

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Perfil actualizado'
                          : 'No fue posible actualizar',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
