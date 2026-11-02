import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/debt_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/debt_provider.dart';

/// Pantalla para crear o editar una deuda.
class CreateDebtScreen extends StatefulWidget {
  final DebtModel? debt;

  const CreateDebtScreen({super.key, this.debt});

  @override
  State<CreateDebtScreen> createState() => _CreateDebtScreenState();
}

class _CreateDebtScreenState extends State<CreateDebtScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _creditorController = TextEditingController();

  final TextEditingController _amountController = TextEditingController();

  final TextEditingController _interestController = TextEditingController();

  final TextEditingController _termController = TextEditingController();

  DateTime? _startDate;

  bool _reminderEnabled = false;

  @override
  void dispose() {
    _creditorController.dispose();
    _amountController.dispose();
    _interestController.dispose();
    _termController.dispose();
    super.dispose();
  }

  /// Muestra el selector de fecha de inicio.
  Future<void> _selectStartDate() async {
    final DateTime now = DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar fecha de inicio',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selectedDate == null) return;

    setState(() {
      _startDate = selectedDate;
    });
  }

  /// Formatea la fecha para mostrarla en pantalla.
  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  /// Valida y procesa el formulario.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de inicio.')),
      );
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();
    final DebtProvider debtProvider = context.read<DebtProvider>();

    final int? idUsuario = authProvider.currentUser?.idUsuario;

    if (idUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al usuario.')),
      );
      return;
    }

    final double montoTotal = double.parse(
      _amountController.text.replaceAll(',', '.'),
    );

    final double tasaInteres = _interestController.text.trim().isEmpty
        ? 0
        : double.parse(_interestController.text.replaceAll(',', '.'));

    final int plazo = int.parse(_termController.text);

    // Conserva los datos originales cuando se está editando.
    final DebtModel? existingDebt = widget.debt;

    final DebtModel debt = DebtModel(
      idDeuda: existingDebt?.idDeuda,
      acreedor: _creditorController.text.trim(),
      montoTotal: montoTotal,

      // Conserva el saldo pendiente y no lo reinicia al editar.
      saldoPendiente: existingDebt?.saldoPendiente ?? montoTotal,

      tasaInteres: tasaInteres,
      plazo: plazo,
      fechaInicio: _startDate!.toIso8601String(),
      recordatorio: _reminderEnabled,
      estado: existingDebt?.estado ?? 'Activa',
      idUsuario: existingDebt?.idUsuario ?? idUsuario,
      fechaRegistro:
          existingDebt?.fechaRegistro ?? DateTime.now().toIso8601String(),
    );

    // Ejecuta la operación correspondiente según el modo del formulario.
    final bool success = existingDebt == null
        ? await debtProvider.createDebt(debt)
        : await debtProvider.updateDebt(debt);

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingDebt == null
                ? 'Deuda creada correctamente.'
                : 'Deuda actualizada correctamente.',
          ),
        ),
      );

      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          debtProvider.errorMessage ??
              (existingDebt == null
                  ? 'No se pudo crear la deuda.'
                  : 'No se pudo actualizar la deuda.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: Text(
          widget.debt == null ? 'Crear deuda' : 'Editar deuda',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
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
                const Text(
                  'Información de la deuda',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF17324D),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.debt == null
                      ? 'Ingresa los datos necesarios para registrar tu deuda.'
                      : 'Actualiza la información de tu deuda.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF667085),
                  ),
                ),

                const SizedBox(height: 20),

                _buildField(
                  controller: _creditorController,
                  label: 'Acreedor',
                  hint: 'Ej. Banco, persona o entidad',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el acreedor.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _buildField(
                  controller: _amountController,
                  label: 'Monto de la deuda',
                  hint: 'Ingresa el monto de la deuda',
                  icon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el monto de la deuda.';
                    }

                    final double? amount = double.tryParse(
                      value.replaceAll(',', '.'),
                    );

                    if (amount == null || amount <= 0) {
                      return 'El monto debe ser mayor que cero.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _buildField(
                  controller: _interestController,
                  label: 'Tasa de interés E.A. (opcional)',
                  hint: 'Ej. 2.5',
                  icon: Icons.percent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    final double? interest = double.tryParse(
                      value.replaceAll(',', '.'),
                    );

                    if (interest == null || interest < 0) {
                      return 'Ingresa una tasa válida.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _buildField(
                  controller: _termController,
                  label: 'Plazo',
                  hint: 'Número de meses',
                  icon: Icons.calendar_month_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el plazo.';
                    }

                    final int? term = int.tryParse(value);

                    if (term == null || term <= 0) {
                      return 'El plazo debe ser mayor que cero.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _buildDateField(),

                const SizedBox(height: 14),

                _buildReminderField(),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      widget.debt == null ? 'Crear deuda' : 'Guardar cambios',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Campo de texto reutilizable para el formulario.
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E7EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
        ),
      ),
    );
  }

  /// Campo para seleccionar la fecha de inicio.
  Widget _buildDateField() {
    return InkWell(
      onTap: _selectStartDate,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de inicio',
          prefixIcon: const Icon(Icons.event_outlined),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E7EF)),
          ),
        ),
        child: Text(
          _startDate == null
              ? 'Selecciona una fecha'
              : _formatDate(_startDate!),
          style: TextStyle(
            fontSize: 16,
            color: _startDate == null
                ? const Color(0xFF667085)
                : const Color(0xFF171717),
          ),
        ),
      ),
    );
  }

  /// Interruptor para activar o desactivar el recordatorio.
  Widget _buildReminderField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Recordatorio de pago',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _reminderEnabled ? 'Activado' : 'Desactivado',
          style: const TextStyle(fontSize: 13, color: Color(0xFF667085)),
        ),
        value: _reminderEnabled,
        activeThumbColor: const Color(0xFF2196F3),
        onChanged: (value) {
          setState(() {
            _reminderEnabled = value;
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Si existe una deuda, carga sus datos para editarlos.
    final DebtModel? debt = widget.debt;

    if (debt != null) {
      _creditorController.text = debt.acreedor;
      _amountController.text = debt.montoTotal.toString();
      _interestController.text = debt.tasaInteres.toString();
      _termController.text = debt.plazo?.toString() ?? '';

      _startDate = DateTime.tryParse(debt.fechaInicio);
      _reminderEnabled = debt.recordatorio;
    }
  }
}
