import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'register_screen.dart';
import '../../main/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pantalla de inicio de sesión para que los usuarios puedan ingresar a la aplicación.
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

  bool _obscurePassword = true;
  bool _rememberEmail = false;

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
            CustomTextField(
              controller: _correoController,
              label: 'Correo',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.email),
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _contrasenaController,
              label: 'Contrasena',
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: _login,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),

            //checkbox
            CheckboxListTile(
              value: _rememberEmail,
              onChanged: (value) {
                setState(() {
                  _rememberEmail = value ?? false;
                });
              },
              title: const Text('Recordar correo'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: 'Iniciar sesion',
              isLoading: authProvider.isLoading,
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
      final prefs = await SharedPreferences.getInstance();

      if (_rememberEmail) {
        await prefs.setBool('remember_email', true);
        await prefs.setString(
          'remembered_email',
          _correoController.text.trim(),
        );
      } else {
        await prefs.remove('remember_email');
        await prefs.remove('remembered_email');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
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

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();

    final remember = prefs.getBool('remember_email') ?? false;
    final email = prefs.getString('remembered_email') ?? '';

    setState(() {
      _rememberEmail = remember;

      if (remember) {
        _correoController.text = email;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }
}
