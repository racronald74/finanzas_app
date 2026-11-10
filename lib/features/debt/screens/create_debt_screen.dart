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

  /// Detecta si está activo el tema de alto contraste.
  bool _isHighContrast(BuildContext context) {
    return Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);
  }

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
    final bool highContrast = _isHighContrast(context);

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar fecha de inicio',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',

      // Adapta el selector de fecha al alto contraste.
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

    // Ejecuta la operación según el modo del formulario.
    final bool success = existingDebt == null
        ? await debtProvider.createDebt(debt)
        : await debtProvider.updateDebt(debt);

    if (!mounted) return;

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
    final bool highContrast = _isHighContrast(context);

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // Adapta el fondo al tema activo.
      backgroundColor: highContrast ? Colors.white : const Color(0xFFF5F8FC),

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
                Text(
                  'Información de la deuda',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: highContrast
                        ? Colors.black
                        : const Color(0xFF17324D),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.debt == null
                      ? 'Ingresa los datos necesarios para registrar tu deuda.'
                      : 'Actualiza la información de tu deuda.',
                  style: TextStyle(
                    fontSize: 14,
                    color: highContrast
                        ? Colors.black
                        : const Color(0xFF667085),
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

                // Botón principal del formulario.
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: highContrast ? 0 : 1,
                      side: highContrast
                          ? const BorderSide(color: Colors.black, width: 1.5)
                          : BorderSide.none,
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

                // Botón para cancelar el formulario.
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: highContrast
                          ? Colors.black
                          : primaryColor,
                    ),
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
    final bool highContrast = _isHighContrast(context);

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: highContrast ? Colors.black : null),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: highContrast ? Colors.black : null),
        labelStyle: TextStyle(color: highContrast ? Colors.black : null),
        hintStyle: TextStyle(color: highContrast ? Colors.black54 : null),
        errorStyle: const TextStyle(color: Colors.red),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: highContrast
              ? const BorderSide(color: Colors.black, width: 1.5)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: highContrast ? Colors.black : const Color(0xFFE1E7EF),
            width: highContrast ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: highContrast ? primaryColor : const Color(0xFF2196F3),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  /// Campo para seleccionar la fecha de inicio.
  Widget _buildDateField() {
    final bool highContrast = _isHighContrast(context);

    return InkWell(
      onTap: _selectStartDate,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de inicio',
          labelStyle: TextStyle(color: highContrast ? Colors.black : null),
          prefixIcon: Icon(
            Icons.event_outlined,
            color: highContrast ? Colors.black : null,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: highContrast
                ? const BorderSide(color: Colors.black, width: 1.5)
                : BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: highContrast ? Colors.black : const Color(0xFFE1E7EF),
              width: highContrast ? 1.5 : 1,
            ),
          ),
        ),
        child: Text(
          _startDate == null
              ? 'Selecciona una fecha'
              : _formatDate(_startDate!),
          style: TextStyle(
            fontSize: 16,
            color: highContrast
                ? Colors.black
                : _startDate == null
                ? const Color(0xFF667085)
                : const Color(0xFF171717),
          ),
        ),
      ),
    );
  }

  /// Interruptor para activar o desactivar el recordatorio.
  Widget _buildReminderField() {
    final bool highContrast = _isHighContrast(context);

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highContrast ? Colors.black : const Color(0xFFE1E7EF),
          width: highContrast ? 1.5 : 1,
        ),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Recordatorio de pago',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: highContrast ? Colors.black : null,
          ),
        ),
        subtitle: Text(
          _reminderEnabled ? 'Activado' : 'Desactivado',
          style: TextStyle(
            fontSize: 13,
            color: highContrast ? Colors.black : const Color(0xFF667085),
          ),
        ),
        value: _reminderEnabled,
        activeThumbColor: primaryColor,
        activeTrackColor: highContrast ? const Color(0xFF003B8E) : null,
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
