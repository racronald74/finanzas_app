import 'package:flutter/material.dart';

/// Pantalla informativa de FinanzasApp.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Actualizar este valor si la versión de pubspec.yaml es diferente.
  static const String appVersion = '1.0.0';

  static const Color _highContrastColor = Color(0xFF003B8E);

  /// Detecta si está activo el modo de alto contraste.
  bool _isHighContrast(BuildContext context) {
    return Theme.of(context).colorScheme.primary == _highContrastColor;
  }

  @override
  Widget build(BuildContext context) {
    final highContrast = _isHighContrast(context);
    final textColor = highContrast ? Colors.black : null;

    return Scaffold(
      backgroundColor: highContrast ? Colors.white : null,
      appBar: AppBar(
        title: const Text(
          'Acerca de la app',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3F6DB5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Identidad visual de la aplicación.
            Image.asset(
              'assets/images/logo_finanzasApp.png',
              height: 120,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            Text(
              'FinanzasApp',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Organiza y administra tus finanzas personales '
              'desde un solo lugar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: highContrast ? Colors.black : Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            // Información de la versión.
            Card(
              color: highContrast ? Colors.white : null,
              shape: _cardShape(highContrast),
              child: ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: highContrast ? _highContrastColor : null,
                ),
                title: Text('Versión', style: TextStyle(color: textColor)),
                subtitle: Text(appVersion, style: TextStyle(color: textColor)),
              ),
            ),

            const SizedBox(height: 20),

            // Descripción de las funcionalidades principales.
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Funcionalidades',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            const SizedBox(height: 10),

            _AboutFeature(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Ingresos y gastos',
              description: 'Registra y consulta tus movimientos financieros.',
              highContrast: highContrast,
            ),

            _AboutFeature(
              icon: Icons.pie_chart_outline,
              title: 'Presupuestos y reportes',
              description: 'Controla tus presupuestos y analiza tus finanzas.',
              highContrast: highContrast,
            ),

            _AboutFeature(
              icon: Icons.savings_outlined,
              title: 'Metas de ahorro',
              description:
                  'Organiza tus objetivos y consulta tu ahorro acumulado.',
              highContrast: highContrast,
            ),

            _AboutFeature(
              icon: Icons.notifications_none,
              title: 'Recordatorios',
              description: 'Consulta avisos de obligaciones, deudas y metas.',
              highContrast: highContrast,
            ),

            const SizedBox(height: 20),

            Divider(
              color: highContrast ? Colors.black : null,
              thickness: highContrast ? 1.5 : null,
            ),

            // Créditos y licencias de recursos gráficos.
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Créditos y licencias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Iconos gráficos utilizados en la aplicación:',
                style: TextStyle(color: textColor),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Designed by Pixel bytes from Flaticon',
              style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
            ),

            const SizedBox(height: 20),

            Text(
              'FinanzasApp',
              style: TextStyle(
                color: highContrast ? Colors.black : Colors.grey,
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Define la forma y el borde de las tarjetas.
  ShapeBorder _cardShape(bool highContrast) {
    return RoundedRectangleBorder(
      side: highContrast
          ? const BorderSide(color: Colors.black, width: 1.5)
          : BorderSide.none,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

/// Elemento reutilizable para describir una funcionalidad.
class _AboutFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool highContrast;

  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: highContrast ? const Color(0xFF003B8E) : const Color(0xFF3F6DB5),
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(color: highContrast ? Colors.black : null),
      ),
      subtitle: Text(
        description,
        style: TextStyle(color: highContrast ? Colors.black : null),
      ),
    );
  }
}
