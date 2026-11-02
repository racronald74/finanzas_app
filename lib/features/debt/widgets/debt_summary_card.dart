import 'package:flutter/material.dart';

import '../../../data/models/debt_model.dart';

/// Tarjeta que muestra un resumen general de las deudas del usuario.
///
/// Calcula automáticamente:
/// - Total de deudas.
/// - Saldo pendiente.
/// - Porcentaje total pagado.
class DebtSummaryCard extends StatelessWidget {
  final List<DebtModel> debts;

  const DebtSummaryCard({super.key, required this.debts});

  /// Calcula el monto total inicial de todas las deudas.
  double get _totalDebts {
    return debts.fold(0, (total, debt) => total + debt.montoTotal);
  }

  /// Calcula el saldo pendiente total.
  double get _pendingBalance {
    return debts.fold(0, (total, debt) => total + debt.saldoPendiente);
  }

  /// Calcula el porcentaje total pagado.
  ///
  /// Se utiliza el total inicial y el saldo pendiente para obtener
  /// cuánto se ha pagado en conjunto.
  double get _paidPercentage {
    if (_totalDebts <= 0) {
      return 0;
    }

    final double paidAmount = _totalDebts - _pendingBalance;

    return (paidAmount / _totalDebts).clamp(0.0, 1.0);
  }

  /// Formatea los valores monetarios con separador de miles.
  String _formatAmount(double amount) {
    final String value = amount.round().toString();
    final StringBuffer formatted = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) {
        formatted.write('.');
      }

      formatted.write(value[i]);
    }

    return '\$$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final int percentage = (_paidPercentage * 100).round();

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total de deudas.
            Expanded(
              child: _SummaryItem(
                title: 'Total deudas',
                value: _formatAmount(_totalDebts),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFF8B3DFF),
                iconBackground: const Color(0xFFE9D9FF),
              ),
            ),

            const _SummaryDivider(),

            // Saldo pendiente.
            Expanded(
              child: _SummaryItem(
                title: 'Saldo pendiente',
                value: _formatAmount(_pendingBalance),
                icon: Icons.monetization_on_outlined,
                iconColor: const Color(0xFF16B86A),
                iconBackground: const Color(0xFFD7F3E5),
              ),
            ),

            const _SummaryDivider(),

            // Progreso total.
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Progreso total',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Indicador circular del porcentaje pagado.
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            value: _paidPercentage,
                            strokeWidth: 8,
                            backgroundColor: Colors.blue.shade50,
                          ),
                        ),

                        // Ajusta el texto para evitar que se oculte.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$percentage%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elemento reutilizable para los indicadores de la tarjeta.
class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 23, // Tamaño del círculo.
          backgroundColor: iconBackground,
          child: Icon(
            icon,
            color: iconColor,
            size: 24, // Tamaño del icono.
          ),
        ),
      ],
    );
  }
}

/// Separador vertical entre los indicadores.
class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 76, color: Colors.grey.shade300);
  }
}
