import 'package:flutter/material.dart';

/// Pantalla de ayuda y soporte de FinanzasApp.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const Color primaryColor = Color(0xFF3F6DB5);
  static const Color highContrastColor = Color(0xFF003B8E);

  /// Detecta si está activo el modo de alto contraste.
  bool _isHighContrast(BuildContext context) {
    return Theme.of(context).colorScheme.primary == highContrastColor;
  }

  @override
  Widget build(BuildContext context) {
    final highContrast = _isHighContrast(context);
    final textColor = highContrast ? Colors.black : null;

    return Scaffold(
      backgroundColor: highContrast ? Colors.white : null,
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
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 65,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¿Cómo podemos ayudarte?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consulta las siguientes guías para conocer '
                    'las funcionalidades de FinanzasApp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Guía de funcionalidades',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 12),

            _HelpItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              description:
                  'Consulta el saldo disponible, los ingresos y gastos '
                  'del mes, el ahorro acumulado y los próximos compromisos.',
              highContrast: highContrast,
            ),

            _HelpItem(
              icon: Icons.trending_up,
              title: 'Ingresos y gastos',
              description:
                  'Registra tus ingresos y gastos para mantener '
                  'actualizada la información de tus finanzas.',
              highContrast: highContrast,
            ),

            _HelpItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Presupuestos',
              description:
                  'Consulta y administra los límites de gastos '
                  'establecidos para tus categorías.',
              highContrast: highContrast,
            ),

            _HelpItem(
              icon: Icons.savings_outlined,
              title: 'Metas de ahorro',
              description:
                  'Crea objetivos de ahorro, registra aportes '
                  'y consulta el avance de cada meta.',
              highContrast: highContrast,
            ),

            _HelpItem(
              icon: Icons.credit_card_outlined,
              title: 'Deudas',
              description:
                  'Registra tus deudas, consulta los saldos pendientes '
                  'y administra los pagos y abonos.',
              highContrast: highContrast,
            ),

            _HelpItem(
              icon: Icons.receipt_long_outlined,
              title: 'Obligaciones',
              description:
                  'Administra tus obligaciones y consulta sus '
                  'fechas de vencimiento y estados de pago.',
              highContrast: highContrast,
            ),

            _HelpItem(
              icon: Icons.bar_chart_outlined,
              title: 'Reportes',
              description:
                  'Consulta los resultados financieros mediante '
                  'resúmenes y gráficos por período.',
              highContrast: highContrast,
            ),

            _HelpItem(
              icon: Icons.notifications_none,
              title: 'Notificaciones',
              description:
                  'Consulta los recordatorios relacionados con '
                  'tus metas, deudas y obligaciones.',
              highContrast: highContrast,
            ),

            const SizedBox(height: 28),

            // Explicación del cálculo del saldo disponible.
            Text(
              '¿Cómo funciona mi saldo disponible?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'El saldo disponible representa el dinero resultante '
              'de considerar los ingresos y gastos registrados '
              'en FinanzasApp.',
              style: TextStyle(color: textColor),
            ),

            const SizedBox(height: 12),

            _BalanceHelpItem(
              icon: Icons.trending_up,
              title: 'Aumentan el saldo',
              description: 'Los ingresos registrados en la aplicación.',
              highContrast: highContrast,
            ),

            _BalanceHelpItem(
              icon: Icons.trending_down,
              title: 'Disminuyen el saldo',
              description:
                  'Los gastos manuales, los pagos y abonos de deudas '
                  'y los pagos de obligaciones.',
              highContrast: highContrast,
            ),

            // Explicación del tratamiento de las metas de ahorro.
            Card(
              color: highContrast ? Colors.white : null,
              shape: _cardShape(highContrast),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.savings_outlined, color: primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '¿Qué sucede con las metas de ahorro?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Los aportes registrados en las metas aumentan '
                      'el ahorro acumulado y permiten consultar el '
                      'progreso de cada objetivo. Sin embargo, estos '
                      'aportes no descuentan el saldo disponible.\n\n'
                      'Las metas funcionan como un mecanismo de '
                      'seguimiento del ahorro y no representan una '
                      'salida adicional de dinero dentro del cálculo '
                      'del saldo disponible.',
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Importante: registra tus ingresos, gastos, pagos '
              'de deudas y obligaciones oportunamente para mantener '
              'actualizado tu saldo disponible.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: highContrast ? Colors.black : Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Preguntas frecuentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 12),

            _FaqItem(
              question: '¿Cómo actualizo mis datos personales?',
              answer:
                  'Abre el menú del avatar y selecciona '
                  'Datos personales. Allí puedes modificar tu nombre '
                  'y correo electrónico.',
              highContrast: highContrast,
            ),

            _FaqItem(
              question: '¿Cómo consulto mi saldo disponible?',
              answer:
                  'Ingresa al Dashboard para consultar el resumen '
                  'financiero y el saldo disponible.',
              highContrast: highContrast,
            ),

            _FaqItem(
              question: '¿Dónde puedo consultar mis pagos pendientes?',
              answer:
                  'Puedes consultar tus obligaciones y deudas '
                  'desde sus respectivos módulos.',
              highContrast: highContrast,
            ),

            _FaqItem(
              question: '¿Cómo reviso mis resultados financieros?',
              answer:
                  'Ingresa al módulo Reportes y selecciona '
                  'el período que deseas consultar.',
              highContrast: highContrast,
            ),

            const SizedBox(height: 24),

            Divider(
              color: highContrast ? Colors.black : null,
              thickness: highContrast ? 1.5 : null,
            ),

            Center(
              child: Text(
                'FinanzasApp',
                style: TextStyle(
                  color: highContrast ? Colors.black : Colors.grey,
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

/// Elemento informativo sobre el efecto de los movimientos en el saldo.
class _BalanceHelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool highContrast;

  const _BalanceHelpItem({
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
        color: highContrast
            ? HelpScreen.highContrastColor
            : HelpScreen.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: highContrast ? Colors.black : null,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(color: highContrast ? Colors.black : null),
      ),
    );
  }
}

/// Elemento desplegable para explicar cada funcionalidad.
class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool highContrast;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highContrast ? Colors.white : null,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: highContrast
            ? const BorderSide(color: Colors.black, width: 1.5)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: highContrast
              ? HelpScreen.highContrastColor
              : HelpScreen.primaryColor,
        ),
        iconColor: highContrast ? Colors.black : null,
        collapsedIconColor: highContrast ? Colors.black : null,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: highContrast ? Colors.black : null,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              description,
              style: TextStyle(color: highContrast ? Colors.black : null),
            ),
          ),
        ],
      ),
    );
  }
}

/// Elemento desplegable para las preguntas frecuentes.
class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  final bool highContrast;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highContrast ? Colors.white : null,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: highContrast
            ? const BorderSide(color: Colors.black, width: 1.5)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.question_answer_outlined,
          color: highContrast
              ? HelpScreen.highContrastColor
              : HelpScreen.primaryColor,
        ),
        iconColor: highContrast ? Colors.black : null,
        collapsedIconColor: highContrast ? Colors.black : null,
        title: Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: highContrast ? Colors.black : null,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: TextStyle(color: highContrast ? Colors.black : null),
            ),
          ),
        ],
      ),
    );
  }
}
