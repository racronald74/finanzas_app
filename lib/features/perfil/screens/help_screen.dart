import 'package:flutter/material.dart';

/// Pantalla de ayuda y soporte de FinanzasApp.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const Color primaryColor = Color(0xFF3F6DB5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ayuda y soporte',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Presentación de la sección de ayuda.
            const Center(
              child: Column(
                children: [
                  Icon(Icons.support_agent, size: 65, color: primaryColor),
                  SizedBox(height: 12),
                  Text(
                    '¿Cómo podemos ayudarte?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Consulta las siguientes guías para conocer '
                    'las funcionalidades de FinanzasApp.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Guía de funcionalidades',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _HelpItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              description:
                  'Consulta el saldo disponible, los ingresos y gastos '
                  'del mes, el ahorro acumulado y los próximos compromisos.',
            ),

            _HelpItem(
              icon: Icons.trending_up,
              title: 'Ingresos y gastos',
              description:
                  'Registra tus ingresos y gastos para mantener '
                  'actualizada la información de tus finanzas.',
            ),

            _HelpItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Presupuestos',
              description:
                  'Consulta y administra los límites de gastos '
                  'establecidos para tus categorías.',
            ),

            _HelpItem(
              icon: Icons.savings_outlined,
              title: 'Metas de ahorro',
              description:
                  'Crea objetivos de ahorro, registra aportes '
                  'y consulta el avance de cada meta.',
            ),

            _HelpItem(
              icon: Icons.credit_card_outlined,
              title: 'Deudas',
              description:
                  'Registra tus deudas, consulta los saldos pendientes '
                  'y administra los pagos y abonos.',
            ),

            _HelpItem(
              icon: Icons.receipt_long_outlined,
              title: 'Obligaciones',
              description:
                  'Administra tus obligaciones y consulta sus '
                  'fechas de vencimiento y estados de pago.',
            ),

            _HelpItem(
              icon: Icons.bar_chart_outlined,
              title: 'Reportes',
              description:
                  'Consulta los resultados financieros mediante '
                  'resúmenes y gráficos por período.',
            ),

            _HelpItem(
              icon: Icons.notifications_none,
              title: 'Notificaciones',
              description:
                  'Consulta los recordatorios relacionados con '
                  'tus metas, deudas y obligaciones.',
            ),

            const SizedBox(height: 28),

            // Explicación del cálculo del saldo disponible.
            const SizedBox(height: 28),

            const Text(
              '¿Cómo funciona mi saldo disponible?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const Text(
              'El saldo disponible representa el dinero resultante '
              'de considerar los ingresos y gastos registrados '
              'en FinanzasApp.',
            ),

            const SizedBox(height: 12),

            _BalanceHelpItem(
              icon: Icons.trending_up,
              title: 'Aumentan el saldo',
              description: 'Los ingresos registrados en la aplicación.',
            ),

            _BalanceHelpItem(
              icon: Icons.trending_down,
              title: 'Disminuyen el saldo',
              description:
                  'Los gastos manuales, los pagos y abonos de deudas '
                  'y los pagos de obligaciones.',
            ),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          color: HelpScreen.primaryColor,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '¿Qué sucede con las metas de ahorro?',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Los aportes registrados en las metas aumentan '
                      'el ahorro acumulado y permiten consultar el '
                      'progreso de cada objetivo. Sin embargo, estos '
                      'aportes no descuentan el saldo disponible.\n\n'
                      'Las metas funcionan como un mecanismo de '
                      'seguimiento del ahorro y no representan una '
                      'salida adicional de dinero dentro del cálculo '
                      'del saldo disponible.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Importante: registra tus ingresos, gastos, pagos '
              'de deudas y obligaciones oportunamente para mantener '
              'actualizado tu saldo disponible.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),

            const Text(
              'Preguntas frecuentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const _FaqItem(
              question: '¿Cómo actualizo mis datos personales?',
              answer:
                  'Abre el menú del avatar y selecciona '
                  'Datos personales. Allí puedes modificar tu nombre '
                  'y correo electrónico.',
            ),

            const _FaqItem(
              question: '¿Cómo consulto mi saldo disponible?',
              answer:
                  'Ingresa al Dashboard para consultar el resumen '
                  'financiero y el saldo disponible.',
            ),

            const _FaqItem(
              question: '¿Dónde puedo consultar mis pagos pendientes?',
              answer:
                  'Puedes consultar tus obligaciones y deudas '
                  'desde sus respectivos módulos.',
            ),

            const _FaqItem(
              question: '¿Cómo reviso mis resultados financieros?',
              answer:
                  'Ingresa al módulo Reportes y selecciona '
                  'el período que deseas consultar.',
            ),

            const SizedBox(height: 24),

            const Divider(),

            const Center(
              child: Text(
                'FinanzasApp',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Elemento informativo sobre el efecto de los movimientos en el saldo.
class _BalanceHelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BalanceHelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: HelpScreen.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(description),
    );
  }
}

/// Elemento desplegable para explicar cada funcionalidad.
class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline, color: HelpScreen.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Text(description)],
      ),
    );
  }
}

/// Elemento desplegable para las preguntas frecuentes.
class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(
          Icons.question_answer_outlined,
          color: HelpScreen.primaryColor,
        ),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [Align(alignment: Alignment.centerLeft, child: Text(answer))],
      ),
    );
  }
}
