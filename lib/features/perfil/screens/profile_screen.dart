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

  /// Detecta si está activo el modo de alto contraste.
  bool _isHighContrast(BuildContext context) {
    return Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);
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
    final highContrast = _isHighContrast(context);

    // Define los colores de los campos según el tema.
    final textColor = highContrast ? Colors.black : null;
    final borderColor = highContrast ? Colors.black : null;

    if (user == null) {
      return Scaffold(
        backgroundColor: highContrast ? Colors.white : null,
        appBar: AppBar(title: const Text('Datos personales')),
        body: Center(
          child: Text(
            'No hay un usuario autenticado',
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: highContrast ? Colors.white : null,
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
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: highContrast
                          ? const Color(0xFF003B8E)
                          : null,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.person, size: 46),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.nombre,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Información de tu cuenta',
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Campo editable del nombre.
              Text(
                'Nombre completo',
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration(
                  icon: Icons.person_outline,
                  hint: 'Ingrese su nombre',
                  highContrast: highContrast,
                  borderColor: borderColor,
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
              Text(
                'Correo electrónico',
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textColor),
                decoration: _buildInputDecoration(
                  icon: Icons.email_outlined,
                  hint: 'Ingrese su correo',
                  highContrast: highContrast,
                  borderColor: borderColor,
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
              Text(
                'Información de la cuenta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_outlined, color: textColor),
                title: Text(
                  'Fecha de registro',
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  _formatDate(user.fechaRegistro),
                  style: TextStyle(color: textColor),
                ),
              ),

              Divider(
                color: highContrast ? Colors.black : null,
                thickness: highContrast ? 1.5 : null,
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: textColor,
                ),
                title: Text(
                  'Ingreso fijo mensual',
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  '\$ ${user.ingresoFijoMensual.toStringAsFixed(0)}',
                  style: TextStyle(color: textColor),
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
                    backgroundColor: highContrast
                        ? const Color(0xFF003B8E)
                        : const Color(0xFF3F6DB5),
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

  /// Construye la decoración de los campos del formulario.
  InputDecoration _buildInputDecoration({
    required IconData icon,
    required String hint,
    required bool highContrast,
    Color? borderColor,
  }) {
    // Define el borde de los campos según el tema activo.
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(
        color: borderColor ?? Colors.grey,
        width: highContrast ? 1.5 : 1,
      ),
    );

    return InputDecoration(
      prefixIcon: Icon(icon, color: highContrast ? Colors.black : null),
      hintText: hint,
      hintStyle: TextStyle(color: highContrast ? Colors.black54 : null),
      border: border,
      enabledBorder: border,
      focusedBorder: highContrast
          ? border.copyWith(
              borderSide: const BorderSide(color: Color(0xFF003B8E), width: 2),
            )
          : null,
    );
  }
}
