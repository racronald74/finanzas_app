import 'package:flutter/material.dart';

import '../../../data/models/debt_model.dart';
import '../../../shared/helpers/currency_formatter.dart';

/// Tarjeta reutilizable para mostrar una deuda.
///
/// Permite consultar el resumen de la deuda y ejecutar
/// las acciones de detalle y pago mediante callbacks.
class DebtCard extends StatelessWidget {
  final DebtModel debt;
  final VoidCallback? onDetail;
  final VoidCallback? onPay;

  const DebtCard({super.key, required this.debt, this.onDetail, this.onPay});

  /// Calcula el porcentaje pagado de la deuda.
  double get _paidPercentage {
    if (debt.montoTotal <= 0) return 0;

    final double paid = debt.montoTotal - debt.saldoPendiente;

    return (paid / debt.montoTotal).clamp(0.0, 1.0);
  }

  /// Convierte el porcentaje a un valor entero.
  int get _percentage => (_paidPercentage * 100).round();

  /// Indica si la deuda ya fue pagada.
  bool get _isPaid {
    return debt.estado == 'Pagada' || debt.saldoPendiente <= 0;
  }

  /// Determina el estado que se mostrará en la tarjeta.
  String get _displayStatus {
    if (_isPaid) return 'Pagada';

    final DateTime? dueDate = _calculateDueDate();

    if (dueDate != null) {
      final DateTime today = DateTime.now();

      final DateTime currentDate = DateTime(today.year, today.month, today.day);

      if (currentDate.isAfter(dueDate)) {
        return 'Vencida';
      }
    }

    return 'Activa';
  }

  /// Calcula la fecha de vencimiento sumando el plazo.
  DateTime? _calculateDueDate() {
    final DateTime? startDate = DateTime.tryParse(debt.fechaInicio);

    if (startDate == null || debt.plazo == null) return null;

    final DateTime targetMonth = DateTime(
      startDate.year,
      startDate.month + debt.plazo!,
      1,
    );

    final int lastDay = DateTime(
      targetMonth.year,
      targetMonth.month + 1,
      0,
    ).day;

    final int day = startDate.day > lastDay ? lastDay : startDate.day;

    return DateTime(targetMonth.year, targetMonth.month, day);
  }

  /// Detecta el tema de alto contraste.
  bool _isHighContrast(BuildContext context) {
    return Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);
  }

  @override
  Widget build(BuildContext context) {
    final bool highContrast = _isHighContrast(context);

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: highContrast ? 0 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: highContrast
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(highContrast),
            const SizedBox(height: 16),
            _buildAmounts(highContrast),
            const SizedBox(height: 12),

            // Muestra el valor de la cuota mensual.
            _buildMonthlyInstallment(highContrast),

            const SizedBox(height: 14),
            _buildProgress(highContrast, primaryColor),
            const SizedBox(height: 14),
            _buildAdditionalInfo(highContrast),
            const SizedBox(height: 16),
            _buildActions(highContrast, primaryColor),
          ],
        ),
      ),
    );
  }

  /// Encabezado con acreedor y estado.
  Widget _buildHeader(bool highContrast) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: highContrast ? Colors.white : Colors.blue.shade50,
          child: Container(
            width: 44,
            height: 44,
            decoration: highContrast
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  )
                : null,
            child: Icon(
              Icons.account_balance_outlined,
              color: highContrast ? Colors.black : Colors.blue.shade700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            debt.acreedor,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: highContrast ? Colors.black : null,
            ),
          ),
        ),
        _buildStatus(highContrast),
      ],
    );
  }

  /// Muestra el estado actual de la deuda.
  Widget _buildStatus(bool highContrast) {
    Color backgroundColor;
    Color textColor;

    switch (_displayStatus) {
      case 'Pagada':
        backgroundColor = const Color(0xFFD7F3E5);
        textColor = const Color(0xFF16B86A);
        break;

      case 'Vencida':
        backgroundColor = const Color(0xFFFFE0E0);
        textColor = const Color(0xFFE53935);
        break;

      case 'Activa':
      default:
        backgroundColor = const Color(0xFFD7ECFF);
        textColor = const Color(0xFF2196F3);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highContrast ? Colors.white : backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: highContrast
            ? Border.all(color: Colors.black, width: 1.5)
            : null,
      ),
      child: Text(
        _displayStatus,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: highContrast ? Colors.black : textColor,
        ),
      ),
    );
  }

  /// Muestra el monto inicial y el capital pendiente.
  Widget _buildAmounts(bool highContrast) {
    return Row(
      children: [
        Expanded(
          child: _AmountItem(
            title: 'Monto de la deuda',
            value: CurrencyFormatter.format(debt.montoTotal),
            highContrast: highContrast,
          ),
        ),
        Expanded(
          child: _AmountItem(
            title: 'Capital pendiente',
            value: CurrencyFormatter.format(debt.saldoPendiente),
            highContrast: highContrast,
          ),
        ),
      ],
    );
  }

  /// Muestra el valor de la cuota mensual.
  Widget _buildMonthlyInstallment(bool highContrast) {
    final double? installment = debt.cuotaMensual;

    final String installmentValue = installment != null && installment > 0
        ? CurrencyFormatter.format(installment)
        : 'No definida';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: highContrast ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: highContrast
            ? Border.all(color: Colors.black, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Cuota mensual',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          Flexible(
            child: Text(
              installmentValue,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: highContrast ? Colors.black : const Color(0xFF2196F3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra el progreso de pago.
  Widget _buildProgress(bool highContrast, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso de pago',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: highContrast ? Colors.black : null,
              ),
            ),
            Text(
              '$_percentage%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: highContrast ? Colors.black : Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),

        // Barra de progreso con adaptación al tema.
        Container(
          decoration: highContrast
              ? BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _paidPercentage,
              minHeight: 8,
              backgroundColor: highContrast
                  ? Colors.white
                  : const Color(0xFFD7ECFF),
              valueColor: AlwaysStoppedAnimation<Color>(
                highContrast ? primaryColor : const Color(0xFF2196F3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Formatea la fecha de inicio.
  String _formatStartDate(String fecha) {
    final DateTime? date = DateTime.tryParse(fecha);

    if (date == null) return fecha;

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  /// Muestra información adicional de la deuda.
  Widget _buildAdditionalInfo(bool highContrast) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        _InfoItem(
          icon: Icons.calendar_today_outlined,
          label: 'Inicio',
          value: _formatStartDate(debt.fechaInicio),
          highContrast: highContrast,
        ),
        if (debt.tasaInteres > 0)
          _InfoItem(
            icon: Icons.percent,
            label: 'Interés',
            value: '${debt.tasaInteres}%',
            highContrast: highContrast,
          ),
        if (debt.plazo != null)
          _InfoItem(
            icon: Icons.schedule_outlined,
            label: 'Plazo',
            value: '${debt.plazo}',
            highContrast: highContrast,
          ),
      ],
    );
  }

  /// Botones para consultar el detalle y registrar un pago.
  Widget _buildActions(bool highContrast, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDetail,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Detalle'),
            style: OutlinedButton.styleFrom(
              foregroundColor: highContrast ? Colors.black : primaryColor,
              side: BorderSide(
                color: highContrast ? Colors.black : primaryColor,
                width: highContrast ? 1.5 : 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isPaid ? null : onPay,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Pagar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: highContrast ? primaryColor : null,
              foregroundColor: Colors.white,
              side: highContrast
                  ? const BorderSide(color: Colors.black, width: 1.5)
                  : BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// Componente para mostrar un monto dentro de la tarjeta.
class _AmountItem extends StatelessWidget {
  final String title;
  final String value;
  final bool highContrast;

  const _AmountItem({
    required this.title,
    required this.value,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: highContrast ? Colors.black : Colors.black,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: highContrast ? Colors.black : const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }
}

/// Componente para información secundaria de la deuda.
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highContrast;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.highContrast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: highContrast ? Colors.black : Colors.grey.shade600,
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 12,
            color: highContrast ? Colors.black : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
