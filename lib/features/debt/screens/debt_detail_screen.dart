import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/debt_model.dart';
import '../../../data/models/debt_payment_model.dart';
import '../../../providers/debt_provider.dart';
import '../../../shared/helpers/currency_formatter.dart';
import 'register_debt_payment_screen.dart';
import 'create_debt_screen.dart';
import 'register_extraordinary_payment_screen.dart';

/// Pantalla que muestra el detalle de una deuda y su historial de pagos.
class DebtDetailScreen extends StatefulWidget {
  final DebtModel debt;

  const DebtDetailScreen({super.key, required this.debt});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  late DebtModel _debt;

  /// Detecta si está activo el alto contraste.
  bool get _highContrast =>
      Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

  /// Color principal del tema activo.
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

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

  /// Formatea una fecha para mostrar día, mes y año.
  String _formatDate(String value) {
    final DateTime? date = DateTime.tryParse(value);
    if (date == null) return value;

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  /// Determina el color del estado en el modo normal.
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

  /// Construye una tarjeta adaptable al alto contraste.
  Widget _buildCard({required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: _highContrast ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: _highContrast
            ? const BorderSide(color: Colors.black, width: 1.5)
            : BorderSide.none,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtProvider>();

    return Scaffold(
      backgroundColor: _highContrast ? Colors.white : const Color(0xFFF5F8FC),
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
          // Contenido desplazable del detalle.
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

          // Botones fijos para registrar pagos.
          if (_debt.estado != 'Pagada')
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    Expanded(child: _buildRegisterPaymentButton()),
                    const SizedBox(width: 10),
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
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: _highContrast
                  ? Colors.white
                  : Colors.blue.shade50,
              child: Icon(
                Icons.account_balance_outlined,
                color: _highContrast ? Colors.black : Colors.blue.shade700,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _debt.acreedor,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: _highContrast ? Colors.black : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _highContrast
                    ? Colors.white
                    : _statusColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: _highContrast
                    ? Border.all(color: Colors.black, width: 1.2)
                    : null,
              ),
              child: Text(
                _debt.estado,
                style: TextStyle(
                  color: _highContrast ? Colors.black : _statusColor(),
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

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de la deuda',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _highContrast ? Colors.black : null,
              ),
            ),
            const SizedBox(height: 18),
            _buildAmountRow('Monto de la deuda', _debt.montoTotal),
            const SizedBox(height: 14),
            _buildAmountRow('Capital pendiente', _debt.saldoPendiente),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progreso de pago',
                  style: TextStyle(
                    fontSize: 13,
                    color: _highContrast ? Colors.black : null,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: _highContrast ? Colors.black : _primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: _highContrast
                  ? BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _paidPercentage,
                  minHeight: 9,
                  backgroundColor: _highContrast
                      ? Colors.white
                      : const Color(0xFFD7ECFF),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _highContrast ? _primaryColor : const Color(0xFF2196F3),
                  ),
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
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: _highContrast ? Colors.black : Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            CurrencyFormatter.format(amount),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _highContrast ? Colors.black : const Color(0xFF2196F3),
            ),
          ),
        ),
      ],
    );
  }

  /// Muestra los datos generales de la deuda.
  Widget _buildGeneralInformation() {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información general',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _highContrast ? Colors.black : null,
              ),
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
          Icon(
            icon,
            size: 19,
            color: _highContrast ? Colors.black : Colors.blue.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: _highContrast ? Colors.black : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _highContrast ? Colors.black : null,
              ),
            ),
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
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _highContrast ? Colors.black : null,
          ),
        ),
        const SizedBox(height: 12),
        if (provider.isLoading && payments.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (payments.isEmpty)
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 38,
                      color: _highContrast ? Colors.black : Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No hay pagos registrados.',
                      style: TextStyle(
                        fontSize: 14,
                        color: _highContrast ? Colors.black : Colors.black54,
                      ),
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
    final bool isExtraordinary = payment.tipoPago == 'EXTRAORDINARIO';

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isExtraordinary ? 'Abono extraordinario' : 'Pago realizado',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _highContrast ? Colors.black : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(payment.monto),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _highContrast
                        ? Colors.black
                        : const Color(0xFF16B86A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Fecha: ${_formatDate(payment.fecha)}',
              style: TextStyle(
                fontSize: 13,
                color: _highContrast ? Colors.black : Colors.black54,
              ),
            ),
            if (isExtraordinary && payment.opcionAbono != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  payment.opcionAbono == 'REDUCIR_PLAZO'
                      ? 'Opción: Reducir plazo'
                      : 'Opción: Reducir cuota',
                  style: TextStyle(
                    fontSize: 13,
                    color: _highContrast ? Colors.black : null,
                  ),
                ),
              ),
            if (payment.metodoPago != null && payment.metodoPago!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Método: ${payment.metodoPago}',
                  style: TextStyle(
                    fontSize: 13,
                    color: _highContrast ? Colors.black : null,
                  ),
                ),
              ),
            if (payment.descripcion != null && payment.descripcion!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  payment.descripcion!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _highContrast ? Colors.black : Colors.black54,
                  ),
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
          backgroundColor: _highContrast
              ? _primaryColor
              : const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: _highContrast ? 0 : 1,
          side: _highContrast
              ? const BorderSide(color: Colors.black, width: 1.5)
              : BorderSide.none,
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
          backgroundColor: _highContrast
              ? _primaryColor
              : const Color(0xFF16B86A),
          foregroundColor: Colors.white,
          elevation: _highContrast ? 0 : 1,
          side: _highContrast
              ? const BorderSide(color: Colors.black, width: 1.5)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }

  /// Abre el formulario para editar la deuda actual.
  Future<void> _editDebt() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CreateDebtScreen(debt: _debt)));

    if (mounted) {
      await _loadDetails();
    }
  }

  /// Solicita confirmación antes de eliminar la deuda.
  Future<void> _confirmDeleteDebt() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: _highContrast
            ? RoundedRectangleBorder(
                side: const BorderSide(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
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

    if (confirmed != true || !mounted) return;

    final provider = context.read<DebtProvider>();

    final bool deleted = await provider.deleteDebt(
      _debt.idDeuda!,
      _debt.idUsuario,
    );

    if (!mounted) return;

    if (deleted) {
      Navigator.of(context).pop(true);
    } else {
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
