import 'package:flutter/material.dart';

/// Pantalla informativa de FinanzasApp.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Actualizar este valor si la versión de pubspec.yaml es diferente.
  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

            const Text(
              'FinanzasApp',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Organiza y administra tus finanzas personales '
              'desde un solo lugar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Información de la versión.
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Versión'),
                subtitle: Text(appVersion),
              ),
            ),

            const SizedBox(height: 20),

            // Descripción de las funcionalidades principales.
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Funcionalidades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            _AboutFeature(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Ingresos y gastos',
              description: 'Registra y consulta tus movimientos financieros.',
            ),

            _AboutFeature(
              icon: Icons.pie_chart_outline,
              title: 'Presupuestos y reportes',
              description: 'Controla tus presupuestos y analiza tus finanzas.',
            ),

            _AboutFeature(
              icon: Icons.savings_outlined,
              title: 'Metas de ahorro',
              description:
                  'Organiza tus objetivos y consulta tu ahorro acumulado.',
            ),

            _AboutFeature(
              icon: Icons.notifications_none,
              title: 'Recordatorios',
              description: 'Consulta avisos de obligaciones, deudas y metas.',
            ),

            const SizedBox(height: 20),

            const Divider(),

            // Créditos y licencias de recursos gráficos.
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Créditos y licencias',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Iconos gráficos utilizados en la aplicación:',
              textAlign: TextAlign.left,
            ),

            const SizedBox(height: 8),

            const Text(
              'Designed by Pixel bytes from Flaticon',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 20),

            const Text('FinanzasApp', style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// Elemento reutilizable para describir una funcionalidad.
class _AboutFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF3F6DB5), size: 28),
      title: Text(title),
      subtitle: Text(description),
    );
  }
}
