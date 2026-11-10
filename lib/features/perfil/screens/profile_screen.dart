import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';

/// Pantalla para consultar y actualizar los datos personales.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de los campos editables.
  late final TextEditingController _nombreController;
  late final TextEditingController _correoController;

  @override
  void initState() {
    super.initState();

    // Obtiene los datos del usuario autenticado.
    final user = context.read<AuthProvider>().currentUser;

    _nombreController = TextEditingController(text: user?.nombre ?? '');

    _correoController = TextEditingController(text: user?.correo ?? '');
  }

  @override
  void dispose() {
    // Libera los controladores al cerrar la pantalla.
    _nombreController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  /// Formatea la fecha de registro.
  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) return value;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Guarda los cambios del perfil.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.updateProfile(
      nombre: _nombreController.text,
      correo: _correoController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.profileMessage),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Datos personales')),
        body: const Center(child: Text('No hay un usuario autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Datos personales',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3F6DB5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado del perfil.
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      child: Icon(Icons.person, size: 46),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Información de tu cuenta'),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Campo editable del nombre.
              const Text(
                'Nombre completo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese su nombre',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Campo editable del correo.
              const Text(
                'Correo electrónico',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'Ingrese su correo',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El correo es obligatorio';
                  }

                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Ingrese un correo válido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Datos informativos de la cuenta.
              const Text(
                'Información de la cuenta',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Fecha de registro'),
                subtitle: Text(_formatDate(user.fechaRegistro)),
              ),

              const Divider(),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Ingreso fijo mensual'),
                subtitle: Text(
                  '\$ ${user.ingresoFijoMensual.toStringAsFixed(0)}',
                ),
              ),

              const SizedBox(height: 24),

              // Botón para guardar los cambios.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: authProvider.isLoading ? null : _saveProfile,
                  icon: authProvider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    authProvider.isLoading ? 'Guardando...' : 'Guardar cambios',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F6DB5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
