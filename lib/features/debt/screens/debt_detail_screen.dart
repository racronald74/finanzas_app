import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/debt_model.dart';
import '../../../data/models/debt_payment_model.dart';
import '../../../providers/debt_provider.dart';
import '../../../shared/helpers/currency_formatter.dart';
import 'register_debt_payment_screen.dart';
import 'create_debt_screen.dart';
import 'register_extraordinary_payment_screen.dart';

/// Pantalla que muestra el detalle de una deuda
/// y el historial de pagos registrados.
class DebtDetailScreen extends StatefulWidget {
  final DebtModel debt;

  const DebtDetailScreen({super.key, required this.debt});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  late DebtModel _debt;

  @override
  void initState() {
    super.initState();

    _debt = widget.debt;

    // Carga la información actualizada y los pagos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  /// Consulta la deuda y su historial de pagos.
  Future<void> _loadDetails() async {
    final provider = context.read<DebtProvider>();

    if (_debt.idDeuda == null) return;

    final DebtModel? updatedDebt = await provider.getDebtById(_debt.idDeuda!);

    if (!mounted) return;

    if (updatedDebt != null) {
      setState(() {
        _debt = updatedDebt;
      });
    }

    await provider.loadPayments(_debt.idDeuda!);
  }

  /// Calcula el porcentaje pagado de la deuda.
  double get _paidPercentage {
    if (_debt.montoTotal <= 0) return 0;

    final double paid = _debt.montoTotal - _debt.saldoPendiente;

    return (paid / _debt.montoTotal).clamp(0.0, 1.0);
  }

  /// Formatea una fecha para mostrar únicamente día, mes y año.
  String _formatDate(String value) {
    final DateTime? date = DateTime.tryParse(value);

    if (date == null) return value;

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  /// Determina los colores según el estado de la deuda.
  Color _statusColor() {
    switch (_debt.estado) {
      case 'Pagada':
        return const Color(0xFF16B86A);
      case 'Vencida':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text(
          'Detalle de deuda',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3F73BC),
        foregroundColor: Colors.white,
        elevation: 0,

        // Opciones para editar o eliminar la deuda.
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'editar') {
                _editDebt();
              } else if (value == 'eliminar') {
                _confirmDeleteDebt();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'editar',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar deuda'),
                ),
              ),
              const PopupMenuItem(
                value: 'eliminar',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Eliminar deuda'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Contenido desplazable del detalle de la deuda.
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDebtHeader(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildGeneralInformation(),
                  const SizedBox(height: 20),
                  _buildPaymentHistory(provider),
                ],
              ),
            ),
          ),

          // Botones para registrar pagos ordinarios y extraordinarios.
          if (_debt.estado != 'Pagada')
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    // Botón para registrar un pago ordinario.
                    Expanded(child: _buildRegisterPaymentButton()),
                    const SizedBox(width: 10),

                    // Botón para registrar un abono extraordinario.
                    Expanded(child: _buildRegisterExtraordinaryPaymentButton()),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Encabezado con el nombre del acreedor y estado.
  Widget _buildDebtHeader() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blue.shade50,
              child: Icon(
                Icons.account_balance_outlined,
                color: Colors.blue.shade700,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _debt.acreedor,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _debt.estado,
                style: TextStyle(
                  color: _statusColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Resumen de montos y avance del pago.
  Widget _buildSummaryCard() {
    final int percentage = (_paidPercentage * 100).round();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de la deuda',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            // Muestra el monto inicial y el capital que aún falta pagar.
            _buildAmountRow('Monto de la deuda', _debt.montoTotal),
            const SizedBox(height: 14),
            _buildAmountRow('Capital pendiente', _debt.saldoPendiente),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progreso de pago', style: TextStyle(fontSize: 13)),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _paidPercentage,
                minHeight: 9,
                backgroundColor: const Color(0xFFD7ECFF),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2196F3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Presenta un monto con su título.
  Widget _buildAmountRow(String title, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.black)),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  /// Muestra los datos generales de la deuda.
  Widget _buildGeneralInformation() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información general',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Fecha de inicio',
              _formatDate(_debt.fechaInicio),
            ),
            if (_debt.tasaInteresEA > 0)
              _buildInfoRow(
                Icons.percent,
                'Tasa de interés E.A.',
                '${_debt.tasaInteresEA}%',
              ),
            if (_debt.plazo != null)
              _buildInfoRow(
                Icons.schedule_outlined,
                'Plazo',
                '${_debt.plazo} meses',
              ),

            // Muestra el valor de la cuota mensual calculada.
            _buildInfoRow(
              Icons.payments_outlined,
              'Cuota mensual',
              _debt.cuotaMensual != null && _debt.cuotaMensual! > 0
                  ? CurrencyFormatter.format(_debt.cuotaMensual!)
                  : 'No definida',
            ),

            _buildInfoRow(
              Icons.notifications_none,
              'Recordatorio',
              _debt.recordatorio ? 'Activado' : 'Desactivado',
            ),
            _buildInfoRow(
              Icons.event_note_outlined,
              'Fecha de registro',
              _formatDate(_debt.fechaRegistro),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una fila de información.
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// Muestra el historial de pagos registrados.
  Widget _buildPaymentHistory(DebtProvider provider) {
    final List<DebtPaymentModel> payments = provider.payments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial de pagos (${payments.length})',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (provider.isLoading && payments.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (payments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 38,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No hay pagos registrados.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...payments.map(_buildPaymentItem),
      ],
    );
  }

  /// Construye una tarjeta individual para cada pago.
  Widget _buildPaymentItem(DebtPaymentModel payment) {
    // Identifica si el movimiento es un abono extraordinario.
    final bool isExtraordinary = payment.tipoPago == 'EXTRAORDINARIO';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isExtraordinary ? 'Abono extraordinario' : 'Pago realizado',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(payment.monto),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16B86A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Fecha: ${_formatDate(payment.fecha)}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            if (isExtraordinary && payment.opcionAbono != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  payment.opcionAbono == 'REDUCIR_PLAZO'
                      ? 'Opción: Reducir plazo'
                      : 'Opción: Reducir cuota',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            if (payment.metodoPago != null && payment.metodoPago!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Método: ${payment.metodoPago}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            if (payment.descripcion != null && payment.descripcion!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  payment.descripcion!,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Abre el formulario para registrar un pago ordinario.
  Widget _buildRegisterPaymentButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          final bool? registered = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => RegisterDebtPaymentScreen(debt: _debt),
            ),
          );

          // Actualiza el saldo y el historial después del registro.
          if (registered == true && mounted) {
            await _loadDetails();
          }
        },
        icon: const Icon(Icons.add_card),
        label: const Text(
          'Registrar pago',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  /// Abre el formulario para registrar un abono extraordinario.
  Widget _buildRegisterExtraordinaryPaymentButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () async {
          final bool? registered = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => RegisterExtraordinaryPaymentScreen(debt: _debt),
            ),
          );

          // Actualiza la deuda y el historial después del registro.
          if (registered == true && mounted) {
            await _loadDetails();
          }
        },
        icon: const Icon(Icons.trending_down),
        label: const Text(
          'Abono extra',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF16B86A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  /// Abre el formulario para editar la deuda actual.
  Future<void> _editDebt() async {
    // Navega al formulario enviando la deuda que se desea editar.
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CreateDebtScreen(debt: _debt)));

    // Actualiza la información al regresar del formulario.
    if (mounted) {
      await _loadDetails();
    }
  }

  /// Solicita confirmación antes de eliminar la deuda.
  Future<void> _confirmDeleteDebt() async {
    // Muestra un diálogo para confirmar la eliminación.
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar deuda'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta deuda? '
          'Los pagos desaparecerán del historial de la deuda, '
          'pero los gastos registrados se conservarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    // Si el usuario cancela, no realiza ninguna operación.
    if (confirmed != true || !mounted) return;

    // Solicita al Provider eliminar la deuda.
    final provider = context.read<DebtProvider>();

    final bool deleted = await provider.deleteDebt(
      _debt.idDeuda!,
      _debt.idUsuario,
    );

    if (!mounted) return;

    if (deleted) {
      // Regresa a la pantalla anterior indicando que se eliminó.
      Navigator.of(context).pop(true);
    } else {
      // Informa si ocurrió algún error.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'No se pudo eliminar la deuda.',
          ),
        ),
      );
    }
  }
}
