import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';

/// Pantalla para configurar las preferencias de accesibilidad.
class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  // Valores seleccionados por el usuario.
  String _tamanoTexto = 'normal';
  bool _altoContraste = false;

  // Controla la inicialización de las preferencias.
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Recupera las preferencias del usuario autenticado.
    if (!_inicializado) {
      final usuario = context.read<AuthProvider>().currentUser;

      _tamanoTexto = usuario?.tamanoTexto ?? 'normal';
      _altoContraste = usuario?.altoContraste ?? false;

      _inicializado = true;
    }
  }

  /// Guarda las preferencias mediante AuthProvider.
  Future<void> _guardarPreferencias() async {
    final authProvider = context.read<AuthProvider>();

    final resultado = await authProvider.updateAccessibilityPreferences(
      tamanoTexto: _tamanoTexto,
      altoContraste: _altoContraste,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultado
              ? 'Preferencias de accesibilidad actualizadas'
              : 'No fue posible guardar las preferencias',
        ),
        backgroundColor: resultado ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detecta el modo de alto contraste activo.
    final highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    final textColor = highContrast ? Colors.black : null;

    return Scaffold(
      backgroundColor: highContrast ? Colors.white : null,
      appBar: AppBar(
        title: const Text('Accesibilidad'),
        backgroundColor: highContrast ? Colors.white : null,
        foregroundColor: highContrast ? Colors.black : null,
        elevation: highContrast ? 0 : null,
        bottom: highContrast
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: Divider(height: 2, thickness: 2, color: Colors.black),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Sección de tamaño de texto.
          Text(
            'Tamaño del texto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Selecciona el tamaño de texto que facilite tu lectura.',
            style: TextStyle(color: textColor),
          ),

          const SizedBox(height: 12),

          // Opciones de tamaño de texto.
          RadioGroup<String>(
            groupValue: _tamanoTexto,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _tamanoTexto = value;
                });
              }
            },
            child: Column(
              children: [
                _buildRadioTile(
                  title: 'Normal',
                  subtitle: 'Tamaño estándar',
                  value: 'normal',
                  highContrast: highContrast,
                ),
                _buildRadioTile(
                  title: 'Grande',
                  subtitle: '115 %',
                  value: 'grande',
                  highContrast: highContrast,
                ),
                _buildRadioTile(
                  title: 'Muy grande',
                  subtitle: '130 %',
                  value: 'muy_grande',
                  highContrast: highContrast,
                ),
              ],
            ),
          ),

          Divider(
            height: 32,
            color: highContrast ? Colors.black : null,
            thickness: highContrast ? 1.5 : null,
          ),

          // Sección de alto contraste.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Alto contraste',
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),
            subtitle: Text(
              'Utiliza colores con mayor contraste para facilitar la lectura.',
              style: TextStyle(color: textColor),
            ),
            value: _altoContraste,
            activeThumbColor: highContrast ? const Color(0xFF003B8E) : null,
            activeTrackColor: highContrast ? const Color(0xFF90CAF9) : null,
            onChanged: (value) {
              setState(() {
                _altoContraste = value;
              });
            },
          ),

          const SizedBox(height: 24),

          // Guarda las preferencias seleccionadas.
          ElevatedButton.icon(
            onPressed: _guardarPreferencias,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar preferencias'),
            style: ElevatedButton.styleFrom(
              backgroundColor: highContrast ? const Color(0xFF003B8E) : null,
              foregroundColor: highContrast ? Colors.white : null,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una opción de tamaño de texto.
  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required bool highContrast,
  }) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(color: highContrast ? Colors.black : null),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: highContrast ? Colors.black : null),
      ),
      value: value,
      activeColor: highContrast ? const Color(0xFF003B8E) : null,
      contentPadding: EdgeInsets.zero,
    );
  }
}
