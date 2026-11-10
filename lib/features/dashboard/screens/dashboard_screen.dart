import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_background.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_summary.dart';

/// Formatea los valores monetarios con el símbolo al principio.
String _formatCurrency(double amount) {
  final format = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$ ',
    decimalDigits: 0,
    customPattern: '¤ #,##0',
  );

  // Devuelve el valor con el formato monetario establecido.
  return format.format(amount);
}

/// Detecta si está activo el tema de alto contraste.
bool _isHighContrast(BuildContext context) {
  return Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);
}

/// Pantalla principal del Dashboard.
class DashboardScreen extends StatelessWidget {
  final VoidCallback onAvatarPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onRetry;

  const DashboardScreen({
    super.key,
    required this.onAvatarPressed,
    this.onNotificationPressed,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final highContrast = _isHighContrast(context);

    return Scaffold(
      backgroundColor: highContrast ? Colors.white : null,
      body: AppBackground(
        child: Column(
          children: [
            // Encabezado reutilizable de la aplicación.
            AppHeader(
              greeting: 'Hola',
              subtitle: 'Resumen del día',
              showAvatar: true,
              showNotification: true,
              onAvatarPressed: onAvatarPressed,
              onNotificationPressed: onNotificationPressed,
            ),

            // Escucha los cambios del resumen financiero.
            Expanded(
              child: Consumer<DashboardProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.errorMessage != null) {
                    return _ErrorDashboard(
                      message: provider.errorMessage!,
                      onRetry: onRetry,
                    );
                  }

                  return _DashboardContent(summary: provider.summary);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenido principal del Dashboard.
class _DashboardContent extends StatelessWidget {
  final DashboardSummary summary;

  const _DashboardContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    final highContrast = _isHighContrast(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta principal de saldo disponible a ancho completo.
          SizedBox(
            width: double.infinity,
            child: _FinancialCard(
              title: 'Saldo disponible',
              amount: summary.availableBalance,
              color: Colors.blue.shade700,
              icon: Icons.account_balance_wallet_outlined,
              highlighted: true,
            ),
          ),

          const SizedBox(height: 16),

          // Indicadores mensuales.
          Row(
            children: [
              Expanded(
                child: _FinancialCard(
                  title: 'Ingresos del mes',
                  amount: summary.monthlyIncome,
                  color: Colors.green.shade700,
                  icon: Icons.trending_up,
                  imageAsset: 'assets/images/ingresos_del_mes.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FinancialCard(
                  title: 'Gastos del mes',
                  amount: summary.monthlyExpenses,
                  color: Colors.red.shade700,
                  icon: Icons.trending_down,
                  imageAsset: 'assets/images/gastos_del_mes.png',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Ahorro acumulado en metas.
          _FinancialCard(
            title: 'Ahorro acumulado en metas',
            amount: summary.goalSavings,
            color: Colors.blue.shade700,
            icon: Icons.savings_outlined,
            imageAsset: 'assets/images/ahorro_acumulado.png',
          ),

          // Comparación visual de ingresos y gastos del mes.
          const SizedBox(height: 24),

          _IncomeExpenseChart(
            income: summary.monthlyIncome,
            expenses: summary.monthlyExpenses,
          ),

          const SizedBox(height: 24),

          // Movimientos recientes.
          _SectionTitle(title: 'Últimos movimientos'),
          const SizedBox(height: 8),

          if (summary.recentMovements.isEmpty)
            const _EmptyMessage(message: 'No hay movimientos registrados.')
          else
            ...summary.recentMovements.map((movement) {
              return Card(
                color: highContrast ? Colors.white : null,
                shape: highContrast
                    ? RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: ListTile(
                  leading: Icon(
                    movement.isIncome
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: movement.isIncome ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    movement.title,
                    style: TextStyle(color: highContrast ? Colors.black : null),
                  ),
                  // Convierte la fecha al formato día/mes/año.
                  subtitle: Text(
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(DateTime.parse(movement.date)),
                    style: TextStyle(color: highContrast ? Colors.black : null),
                  ),
                  trailing: Text(
                    '${movement.isIncome ? '+' : '-'}'
                    '${_formatCurrency(movement.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: movement.isIncome
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Obligaciones próximas a vencer.
          _SectionTitle(title: 'Obligaciones pendientes'),
          const SizedBox(height: 8),

          if (summary.upcomingObligations.isEmpty)
            const _EmptyMessage(message: 'No tienes obligaciones pendientes.')
          else
            ...summary.upcomingObligations.take(3).map((obligation) {
              return Card(
                color: highContrast ? Colors.white : null,
                shape: highContrast
                    ? RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: ListTile(
                  leading: const Icon(Icons.event_note, color: Colors.orange),
                  title: Text(
                    obligation.nombre,
                    style: TextStyle(color: highContrast ? Colors.black : null),
                  ),
                  subtitle: Text(
                    'Vence: ${obligation.fechaVencimiento}',
                    style: TextStyle(color: highContrast ? Colors.black : null),
                  ),
                  trailing: Text(
                    _formatCurrency(obligation.monto),
                    style: TextStyle(color: highContrast ? Colors.black : null),
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Deudas con saldo pendiente.
          _SectionTitle(title: 'Deudas pendientes'),
          const SizedBox(height: 8),

          if (summary.pendingDebts.isEmpty)
            const _EmptyMessage(message: 'No tienes deudas pendientes.')
          else
            ...summary.pendingDebts.take(3).map((debt) {
              return Card(
                color: highContrast ? Colors.white : null,
                shape: highContrast
                    ? RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: ListTile(
                  leading: const Icon(
                    Icons.credit_card,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    debt.acreedor,
                    style: TextStyle(color: highContrast ? Colors.black : null),
                  ),
                  subtitle: Text(
                    'Saldo pendiente',
                    style: TextStyle(color: highContrast ? Colors.black : null),
                  ),
                  trailing: Text(
                    _formatCurrency(debt.saldoPendiente),
                    style: TextStyle(color: highContrast ? Colors.black : null),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Tarjeta reutilizable para los indicadores financieros.
class _FinancialCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final String? imageAsset;
  final bool highlighted;

  const _FinancialCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.imageAsset,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final highContrast = _isHighContrast(context);

    return Card(
      // Conserva el fondo azul de la tarjeta principal.
      color: highlighted
          ? Colors.blue.shade700
          : highContrast
          ? Colors.white
          : null,
      // Agrega un borde negro a las tarjetas en alto contraste.
      shape: highContrast
          ? RoundedRectangleBorder(
              side: const BorderSide(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: highlighted
            ? Row(
                children: [
                  // Información del saldo disponible.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: Colors.white),
                        const SizedBox(height: 10),
                        const Text(
                          'Saldo disponible',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatCurrency(amount),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Logo de FinanzasApp con bordes suavemente desvanecidos.
                  Transform.rotate(
                    angle: -0.15,
                    child: ShaderMask(
                      // Aplica una máscara radial para integrar los bordes con la tarjeta.
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (Rect bounds) {
                        return const RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.65, 1.0],
                        ).createShader(bounds);
                      },
                      child: Image.asset(
                        'assets/images/logo_finanzasApp.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Muestra la imagen personalizada o el icono predeterminado.
                  if (imageAsset != null)
                    Image.asset(
                      imageAsset!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    )
                  else
                    Icon(icon, color: color),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(color: highContrast ? Colors.black : null),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatCurrency(amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Gráfico comparativo de ingresos y gastos mensuales.
class _IncomeExpenseChart extends StatelessWidget {
  final double income;
  final double expenses;

  const _IncomeExpenseChart({required this.income, required this.expenses});

  @override
  Widget build(BuildContext context) {
    // Obtiene el valor más alto para calcular las proporciones.
    final maxValue = income > expenses ? income : expenses;

    // Evita divisiones entre cero cuando no existen movimientos.
    final incomeProgress = maxValue > 0 ? income / maxValue : 0.0;
    final expensesProgress = maxValue > 0 ? expenses / maxValue : 0.0;

    final highContrast = _isHighContrast(context);

    return Card(
      color: highContrast ? Colors.white : null,
      shape: highContrast
          ? RoundedRectangleBorder(
              side: const BorderSide(color: Colors.black, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingresos vs. gastos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: highContrast ? Colors.black : null,
              ),
            ),
            const SizedBox(height: 20),

            // Barra de ingresos.
            _ChartBar(
              title: 'Ingresos',
              amount: income,
              progress: incomeProgress.toDouble(),
              color: Colors.green.shade700,
            ),

            const SizedBox(height: 20),

            // Barra de gastos.
            _ChartBar(
              title: 'Gastos',
              amount: expenses,
              progress: expensesProgress.toDouble(),
              color: Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra reutilizable para representar cada indicador.
class _ChartBar extends StatelessWidget {
  final String title;
  final double amount;
  final double progress;
  final Color color;

  const _ChartBar({
    required this.title,
    required this.amount,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final highContrast = _isHighContrast(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre e importe del indicador.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: highContrast ? Colors.black : null,
              ),
            ),
            Text(
              _formatCurrency(amount),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Barra proporcional al valor más alto.
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Título reutilizable para las secciones.
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final highContrast = _isHighContrast(context);

    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: highContrast ? Colors.black : null,
      ),
    );
  }
}

/// Mensaje para secciones sin información.
class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final highContrast = _isHighContrast(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: TextStyle(color: highContrast ? Colors.black : null),
      ),
    );
  }
}

/// Mensaje de error con opción para volver a cargar.
class _ErrorDashboard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorDashboard({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final highContrast = _isHighContrast(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: highContrast ? Colors.black : null,
            ),
            const SizedBox(height: 12),
            Text(
              'No fue posible cargar el Dashboard.',
              style: TextStyle(color: highContrast ? Colors.black : null),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: highContrast ? Colors.black : null),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
