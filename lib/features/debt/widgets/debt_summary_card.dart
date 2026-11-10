import 'package:flutter/material.dart';

import '../../../data/models/debt_model.dart';

/// Tarjeta que muestra un resumen general de las deudas.
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
  double get _paidPercentage {
    if (_totalDebts <= 0) return 0;

    final double paidAmount = _totalDebts - _pendingBalance;

    return (paidAmount / _totalDebts).clamp(0.0, 1.0);
  }

  /// Formatea los valores monetarios.
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

    // Detecta si está activo el alto contraste.
    final bool highContrast =
        Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      color: Colors.white,
      elevation: highContrast ? 0 : 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: highContrast
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
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
                iconColor: highContrast
                    ? Colors.black
                    : const Color(0xFF8B3DFF),
                iconBackground: highContrast
                    ? Colors.white
                    : const Color(0xFFE9D9FF),
                highContrast: highContrast,
                valueColor: highContrast ? Colors.black : Colors.blue,
              ),
            ),

            _SummaryDivider(highContrast: highContrast),

            // Saldo pendiente.
            Expanded(
              child: _SummaryItem(
                title: 'Saldo pendiente',
                value: _formatAmount(_pendingBalance),
                icon: Icons.monetization_on_outlined,
                iconColor: highContrast
                    ? Colors.black
                    : const Color(0xFF16B86A),
                iconBackground: highContrast
                    ? Colors.white
                    : const Color(0xFFD7F3E5),
                highContrast: highContrast,
                valueColor: highContrast ? Colors.black : Colors.blue,
              ),
            ),

            _SummaryDivider(highContrast: highContrast),

            // Progreso total.
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Progreso total',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: highContrast ? Colors.black : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Indicador circular.
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            value: _paidPercentage,
                            strokeWidth: 8,
                            backgroundColor: highContrast
                                ? Colors.white
                                : Colors.blue.shade50,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        ),

                        // Porcentaje pagado.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: highContrast ? Colors.black : Colors.blue,
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
  final Color valueColor;
  final bool highContrast;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.highContrast,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: highContrast ? Colors.black : null,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 23,
          backgroundColor: iconBackground,
          child: Container(
            width: 46,
            height: 46,
            decoration: highContrast
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  )
                : null,
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
      ],
    );
  }
}

/// Separador vertical entre los indicadores.
class _SummaryDivider extends StatelessWidget {
  final bool highContrast;

  const _SummaryDivider({required this.highContrast});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 76,
      color: highContrast ? Colors.black : Colors.grey.shade300,
    );
  }
}
