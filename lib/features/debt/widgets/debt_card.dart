import 'package:flutter/material.dart';

import '../../../data/models/debt_model.dart';
import '../../../shared/helpers/currency_formatter.dart';

/// Tarjeta reutilizable para mostrar una deuda.
///
/// Permite consultar el resumen de la deuda y ejecutar las acciones
/// de detalle y pago mediante callbacks.
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

  /// Convierte el porcentaje a un valor entero para mostrarlo.
  int get _percentage => (_paidPercentage * 100).round();

  /// Indica si la deuda ya fue pagada.
  bool get _isPaid => debt.estado == 'Pagada' || debt.saldoPendiente <= 0;

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

  /// Calcula la fecha de vencimiento sumando el plazo a la fecha de inicio.
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildAmounts(),
            const SizedBox(height: 12),

            // Muestra el valor de la cuota mensual.
            _buildMonthlyInstallment(),

            const SizedBox(height: 14),
            _buildProgress(),
            const SizedBox(height: 14),
            _buildAdditionalInfo(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// Encabezado con acreedor y estado.
  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue.shade50,
          child: Icon(
            Icons.account_balance_outlined,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            debt.acreedor,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        _buildStatus(),
      ],
    );
  }

  /// Muestra el estado actual de la deuda con un color según su estado.
  Widget _buildStatus() {
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
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _displayStatus,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// Muestra el monto inicial de la deuda y el capital pendiente.
  Widget _buildAmounts() {
    return Row(
      children: [
        Expanded(
          child: _AmountItem(
            title: 'Monto de la deuda',
            value: CurrencyFormatter.format(debt.montoTotal),
          ),
        ),
        Expanded(
          child: _AmountItem(
            title: 'Capital pendiente',
            value: CurrencyFormatter.format(debt.saldoPendiente),
          ),
        ),
      ],
    );
  }

  /// Muestra el valor de la cuota mensual de la deuda.
  Widget _buildMonthlyInstallment() {
    // Evita mostrar un valor de cero cuando no existe una cuota calculada.
    final double? installment = debt.cuotaMensual;

    final String installmentValue = installment != null && installment > 0
        ? CurrencyFormatter.format(installment)
        : 'No definida';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Cuota mensual',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            installmentValue,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra el progreso de pago.
  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progreso de pago',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              '$_percentage%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _paidPercentage,
            minHeight: 8,
            backgroundColor: const Color(0xFFD7ECFF),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
        ),
      ],
    );
  }

  /// Formatea la fecha de inicio para mostrar únicamente la fecha.
  String _formatStartDate(String fecha) {
    final DateTime? date = DateTime.tryParse(fecha);

    if (date == null) {
      return fecha;
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  /// Muestra información adicional disponible en el modelo.
  Widget _buildAdditionalInfo() {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        _InfoItem(
          icon: Icons.calendar_today_outlined,
          label: 'Inicio',
          value: _formatStartDate(debt.fechaInicio),
        ),
        if (debt.tasaInteres > 0)
          _InfoItem(
            icon: Icons.percent,
            label: 'Interés',
            value: '${debt.tasaInteres}%',
          ),
        if (debt.plazo != null)
          _InfoItem(
            icon: Icons.schedule_outlined,
            label: 'Plazo',
            value: '${debt.plazo}',
          ),
      ],
    );
  }

  /// Botones para consultar el detalle y registrar un pago.
  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDetail,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Detalle'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isPaid ? null : onPay,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Pagar'),
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

  const _AmountItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2196F3),
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

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 5),
        Text(
          '$label: $value',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
