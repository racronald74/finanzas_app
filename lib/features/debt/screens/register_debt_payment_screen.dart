import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/debt_model.dart';
import '../../../data/models/debt_payment_model.dart';
import '../../../data/models/debt_payment_preview_model.dart';
import '../../../providers/debt_provider.dart';
import '../../../shared/helpers/currency_formatter.dart';

/// Pantalla para registrar un pago de una deuda.
class RegisterDebtPaymentScreen extends StatefulWidget {
  final DebtModel debt;

  const RegisterDebtPaymentScreen({super.key, required this.debt});

  @override
  State<RegisterDebtPaymentScreen> createState() =>
      _RegisterDebtPaymentScreenState();
}

class _RegisterDebtPaymentScreenState extends State<RegisterDebtPaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _methodController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _paymentDate = DateTime.now();

  // Temporizador para evitar solicitar una vista previa en cada pulsación.
  Timer? _previewTimer;

  // Resultado del cálculo de distribución del pago.
  DebtPaymentPreviewModel? _paymentPreview;

  // Controla si se está calculando la vista previa.
  bool _isPreviewLoading = false;

  // Identifica las solicitudes para descartar resultados anteriores.
  int _previewRequestId = 0;

  /// Detecta si está activo el alto contraste.
  bool get _highContrast =>
      Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

  /// Color principal del tema.
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();

    // Precarga la cuota mensual como valor inicial del pago.
    final double? installment = widget.debt.cuotaMensual;

    if (installment != null && installment > 0) {
      _amountController.text = installment.toStringAsFixed(2);
    }

    // Calcula la vista previa después de construir la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _schedulePaymentPreview();
      }
    });
  }

  @override
  void dispose() {
    // Cancela el temporizador pendiente.
    _previewTimer?.cancel();

    // Invalida cualquier solicitud de vista previa en curso.
    _previewRequestId++;

    // Libera los controladores.
    _amountController.dispose();
    _methodController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  /// Permite seleccionar la fecha del pago.
  Future<void> _selectDate() async {
    final bool highContrast = _highContrast;

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar fecha del pago',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        if (!highContrast) return child!;

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003B8E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    setState(() {
      _paymentDate = selectedDate;
    });

    // Recalcula la vista previa con la nueva fecha.
    _schedulePaymentPreview();
  }

  /// Formatea la fecha para mostrarla en pantalla.
  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  /// Convierte la fecha seleccionada a formato ISO.
  String _dateToIso(DateTime date) {
    final DateTime normalizedDate = DateTime(date.year, date.month, date.day);

    return normalizedDate.toIso8601String();
  }

  /// Programa el cálculo de la vista previa del pago ordinario.
  void _schedulePaymentPreview() {
    _previewTimer?.cancel();
    _previewRequestId++;

    final int currentRequestId = _previewRequestId;

    final double? amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    // Si el importe no es válido, limpia la vista previa.
    if (amount == null || amount <= 0) {
      setState(() {
        _paymentPreview = null;
        _isPreviewLoading = false;
      });
      return;
    }

    // Evita calcular importes superiores al saldo pendiente.
    if (amount > widget.debt.saldoPendiente) {
      setState(() {
        _paymentPreview = null;
        _isPreviewLoading = false;
      });
      return;
    }

    // Construye el pago que se utilizará únicamente para simular.
    final payment = DebtPaymentModel(
      monto: amount,
      fecha: _dateToIso(_paymentDate),
      idDeuda: widget.debt.idDeuda!,
      fechaRegistro: DateTime.now().toIso8601String(),
    );

    setState(() {
      _isPreviewLoading = true;
      _paymentPreview = null;
    });

    // Espera un breve intervalo antes de solicitar el cálculo.
    _previewTimer = Timer(const Duration(milliseconds: 400), () async {
      final preview = await context.read<DebtProvider>().previewPayment(
        payment,
      );

      // Descarta resultados de solicitudes anteriores.
      if (!mounted || currentRequestId != _previewRequestId) return;

      setState(() {
        _paymentPreview = preview;
        _isPreviewLoading = false;
      });
    });
  }

  /// Valida y registra el pago mediante DebtProvider.
  Future<void> _registerPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.debt.idDeuda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el identificador de la deuda.'),
        ),
      );
      return;
    }

    final double amount = double.parse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    final DebtPaymentModel payment = DebtPaymentModel(
      monto: amount,
      fecha: _dateToIso(_paymentDate),
      metodoPago: _methodController.text.trim().isEmpty
          ? null
          : _methodController.text.trim(),
      descripcion: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      idDeuda: widget.debt.idDeuda!,
      fechaRegistro: DateTime.now().toIso8601String(),
    );

    final DebtProvider provider = context.read<DebtProvider>();
    final bool success = await provider.registerPayment(payment);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago registrado correctamente.'),
          backgroundColor: Color(0xFF16B86A),
        ),
      );

      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'No fue posible registrar el pago.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Construye una tarjeta adaptable al alto contraste.
  Widget _buildCard({required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: _highContrast ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _highContrast
            ? const BorderSide(color: Colors.black, width: 1.5)
            : BorderSide.none,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final DebtProvider provider = context.watch<DebtProvider>();

    return Scaffold(
      backgroundColor: _highContrast ? Colors.white : const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text(
          'Registrar pago',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3F73BC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDebtSummary(),
                const SizedBox(height: 22),
                Text(
                  'Información del pago',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: _highContrast
                        ? Colors.black
                        : const Color(0xFF17324D),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAmountField(),
                const SizedBox(height: 12),
                _buildPaymentPreview(),
                const SizedBox(height: 14),
                _buildDateField(),
                const SizedBox(height: 14),
                _buildMethodField(),
                const SizedBox(height: 14),
                _buildDescriptionField(),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : _registerPayment,
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text(
                      'Registrar pago',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
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
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _highContrast
                          ? Colors.black
                          : _primaryColor,
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra el acreedor y el saldo pendiente.
  Widget _buildDebtSummary() {
    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.debt.acreedor,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _highContrast ? Colors.black : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Saldo pendiente',
              style: TextStyle(
                fontSize: 13,
                color: _highContrast ? Colors.black : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(widget.debt.saldoPendiente),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _highContrast ? Colors.black : const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Campo para ingresar el monto del pago.
  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: _highContrast ? Colors.black : null),
      onChanged: (_) {
        _schedulePaymentPreview();
      },
      decoration: _inputDecoration(
        label: 'Monto del pago',
        hint: 'Ingresa el monto',
        icon: Icons.attach_money,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresa el monto del pago.';
        }

        final double? amount = double.tryParse(
          value.trim().replaceAll(',', '.'),
        );

        if (amount == null || amount <= 0) {
          return 'El monto debe ser mayor que cero.';
        }

        if (amount > widget.debt.saldoPendiente) {
          return 'El pago supera el saldo pendiente.';
        }

        return null;
      },
    );
  }

  /// Muestra la distribución estimada del pago.
  Widget _buildPaymentPreview() {
    if (_isPreviewLoading) {
      return _buildCard(
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Calculando distribución del pago...')),
            ],
          ),
        ),
      );
    }

    if (_paymentPreview == null) {
      return const SizedBox.shrink();
    }

    final preview = _paymentPreview!;

    return _buildCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución estimada del pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _highContrast ? Colors.black : const Color(0xFF17324D),
              ),
            ),
            const SizedBox(height: 14),
            _buildPreviewRow('Monto del pago', preview.montoPago),
            _buildPreviewRow('Intereses a pagar', preview.interesesPagados),
            _buildPreviewRow('Abono a capital', preview.abonoCapital),
            Divider(
              height: 24,
              color: _highContrast ? Colors.black : null,
              thickness: _highContrast ? 1.5 : null,
            ),
            _buildPreviewRow(
              'Saldo restante',
              preview.saldoRestante,
              highlight: true,
            ),

            // Advierte cuando el importe es inferior a la cuota mensual.
            if (preview.pagoInferiorCuota) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _highContrast ? Colors.white : const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(10),
                  border: _highContrast
                      ? Border.all(color: Colors.black, width: 1.2)
                      : null,
                ),
                child: Text(
                  'El monto ingresado es inferior a la cuota mensual.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _highContrast
                        ? Colors.black
                        : const Color(0xFF9A6700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye una fila con el concepto y su valor monetario.
  Widget _buildPreviewRow(
    String label,
    double amount, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                color: _highContrast ? Colors.black : const Color(0xFF526477),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              CurrencyFormatter.format(amount),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _highContrast
                    ? Colors.black
                    : highlight
                    ? const Color(0xFF2196F3)
                    : const Color(0xFF17324D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Campo para seleccionar la fecha del pago.
  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Fecha del pago',
          icon: Icons.calendar_today_outlined,
        ),
        child: Text(
          _formatDate(_paymentDate),
          style: TextStyle(
            fontSize: 15,
            color: _highContrast ? Colors.black : null,
          ),
        ),
      ),
    );
  }

  /// Campo opcional para indicar el método de pago.
  Widget _buildMethodField() {
    return TextFormField(
      controller: _methodController,
      style: TextStyle(color: _highContrast ? Colors.black : null),
      decoration: _inputDecoration(
        label: 'Método de pago (opcional)',
        hint: 'Ej. Transferencia, efectivo',
        icon: Icons.account_balance_wallet_outlined,
      ),
    );
  }

  /// Campo opcional para agregar una descripción.
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      style: TextStyle(color: _highContrast ? Colors.black : null),
      decoration: _inputDecoration(
        label: 'Descripción (opcional)',
        hint: 'Agrega información adicional',
        icon: Icons.notes_outlined,
      ),
    );
  }

  /// Estilo reutilizable para los campos del formulario.
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final Color borderColor = _highContrast
        ? Colors.black
        : const Color(0xFFE1E7EF);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _highContrast ? Colors.black : null),
      labelStyle: TextStyle(color: _highContrast ? Colors.black : null),
      hintStyle: TextStyle(color: _highContrast ? Colors.black54 : null),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: borderColor,
          width: _highContrast ? 1.5 : 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: borderColor,
          width: _highContrast ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _highContrast ? _primaryColor : const Color(0xFF2196F3),
          width: 1.5,
        ),
      ),
    );
  }
}
