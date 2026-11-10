import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/debt_model.dart';
import '../../../data/models/debt_payment_model.dart';
import '../../../providers/debt_provider.dart';

/// Pantalla para registrar abonos extraordinarios a una deuda.
class RegisterExtraordinaryPaymentScreen extends StatefulWidget {
  final DebtModel debt;

  const RegisterExtraordinaryPaymentScreen({super.key, required this.debt});

  @override
  State<RegisterExtraordinaryPaymentScreen> createState() =>
      _RegisterExtraordinaryPaymentScreenState();
}

class _RegisterExtraordinaryPaymentScreenState
    extends State<RegisterExtraordinaryPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _paymentDate = DateTime.now();

  // Opción de aplicación del abono extraordinario.
  String _selectedOption = 'REDUCIR_PLAZO';

  bool _isSaving = false;

  /// Detecta si está activo el alto contraste.
  bool get _highContrast =>
      Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

  /// Color principal del tema.
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Permite seleccionar la fecha del abono.
  Future<void> _selectDate() async {
    // Convierte la fecha de inicio almacenada como String.
    final debtStartDate = DateTime.parse(widget.debt.fechaInicio);

    // Evita utilizar una fecha inicial anterior al inicio de la deuda.
    final initialDate = _paymentDate.isBefore(debtStartDate)
        ? debtStartDate
        : _paymentDate;

    final bool highContrast = _highContrast;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: debtStartDate,
      lastDate: DateTime.now(),
      helpText: 'Seleccionar fecha del abono',
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

    if (selectedDate != null) {
      setState(() {
        _paymentDate = selectedDate;
      });
    }
  }

  /// Formatea una fecha para mostrarla en pantalla.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Convierte una fecha al formato utilizado por la base de datos.
  String _dateToIso(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Registra el abono extraordinario.
  Future<void> _registerPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final debtId = widget.debt.idDeuda;

    if (debtId == null) {
      _showMessage('No se pudo identificar la deuda.');
      return;
    }

    // Convierte el importe ingresado a número.
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    if (amount == null) {
      _showMessage('Ingresa un importe válido.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Construye el movimiento extraordinario.
    final payment = DebtPaymentModel(
      monto: amount,
      abonoCapital: amount,
      interesesPagados: 0,
      tipoPago: 'EXTRAORDINARIO',
      opcionAbono: _selectedOption,
      fecha: _dateToIso(_paymentDate),
      descripcion: _descriptionController.text.trim(),
      idDeuda: debtId,
      fechaRegistro: _dateToIso(DateTime.now()),
    );

    final provider = Provider.of<DebtProvider>(context, listen: false);

    final success = await provider.registerExtraordinaryPayment(payment);

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      _showMessage('Abono extraordinario registrado correctamente.');
      Navigator.pop(context, true);
    } else {
      _showMessage(provider.errorMessage ?? 'No se pudo registrar el abono.');
    }
  }

  /// Muestra mensajes informativos.
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Construye la decoración común de los campos.
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    final Color borderColor = _highContrast
        ? Colors.black
        : const Color(0xFFE1E7EF);

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _highContrast ? Colors.black : null),
      labelStyle: TextStyle(color: _highContrast ? Colors.black : null),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: borderColor,
          width: _highContrast ? 1.5 : 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: borderColor,
          width: _highContrast ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _highContrast ? _primaryColor : const Color(0xFF3F73BC),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capitalPendiente = widget.debt.saldoCapital;

    return Scaffold(
      backgroundColor: _highContrast ? Colors.white : const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text(
          'Abono extraordinario',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF3F73BC),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Resumen de la deuda seleccionada.
                _buildDebtSummary(capitalPendiente),
                const SizedBox(height: 24),

                // Importe del abono.
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: _highContrast ? Colors.black : null),
                  decoration: _inputDecoration(
                    label: 'Importe del abono',
                    icon: Icons.payments_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el importe del abono.';
                    }

                    final amount = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );

                    if (amount == null || amount <= 0) {
                      return 'Ingresa un importe válido.';
                    }

                    if (amount > capitalPendiente) {
                      return 'El abono no puede superar el capital pendiente.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Fecha del movimiento.
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: _inputDecoration(
                      label: 'Fecha del abono',
                      icon: Icons.calendar_today,
                    ),
                    child: Text(
                      _formatDate(_paymentDate),
                      style: TextStyle(
                        color: _highContrast ? Colors.black : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  '¿Cómo deseas aplicar el abono?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _highContrast ? Colors.black : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Opción para reducir el número de cuotas.
                _buildOptionCard(
                  value: 'REDUCIR_PLAZO',
                  title: 'Reducir plazo',
                  description:
                      'Mantener el valor de la cuota y terminar de pagar '
                      'la deuda en menos tiempo.',
                ),
                const SizedBox(height: 10),

                // Opción para reducir el valor de las cuotas.
                _buildOptionCard(
                  value: 'REDUCIR_CUOTA',
                  title: 'Reducir cuota',
                  description:
                      'Mantener la fecha final de la deuda y disminuir '
                      'el valor de las cuotas.',
                ),
                const SizedBox(height: 18),

                // Descripción opcional del movimiento.
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: TextStyle(color: _highContrast ? Colors.black : null),
                  decoration: _inputDecoration(
                    label: 'Descripción (opcional)',
                    icon: Icons.description_outlined,
                  ),
                ),
                const SizedBox(height: 28),

                // Botón para registrar el abono.
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _registerPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: _highContrast ? 0 : 1,
                      side: _highContrast
                          ? const BorderSide(color: Colors.black, width: 1.5)
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Registrar abono'),
                  ),
                ),
                const SizedBox(height: 12),

                // Botón para cancelar el registro.
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _highContrast
                          ? Colors.black
                          : _primaryColor,
                      side: _highContrast
                          ? const BorderSide(color: Colors.black, width: 1.5)
                          : null,
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

  /// Presenta el resumen del capital pendiente.
  Widget _buildDebtSummary(double capitalPendiente) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: _highContrast
            ? Border.all(color: Colors.black, width: 1.5)
            : null,
        boxShadow: _highContrast
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
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
            'Capital pendiente',
            style: TextStyle(color: _highContrast ? Colors.black : Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${capitalPendiente.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _highContrast ? Colors.black : const Color(0xFF3F73BC),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una opción de aplicación del abono.
  Widget _buildOptionCard({
    required String value,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedOption == value;

    final Color borderColor = _highContrast
        ? Colors.black
        : isSelected
        ? const Color(0xFF3F73BC)
        : Colors.grey.shade300;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: _highContrast
              ? 1.5
              : isSelected
              ? 1.2
              : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedOption = value;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _highContrast
                    ? Colors.black
                    : isSelected
                    ? const Color(0xFF3F73BC)
                    : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _highContrast ? Colors.black : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: _highContrast ? Colors.black : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
