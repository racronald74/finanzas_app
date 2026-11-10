import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../data/models/expense_model.dart';
import 'package:intl/intl.dart';

/// Pantalla para registrar o editar un gasto.
class AddExpenseScreen extends StatefulWidget {
  /// Gasto que será editado.
  final ExpenseModel? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  /// Llave del formulario.
  final _formKey = GlobalKey<FormState>();

  /// Controlador del campo Nombre.
  final TextEditingController _nombreController = TextEditingController();

  /// Controlador del campo Monto.
  final TextEditingController _montoController = TextEditingController();

  /// Controlador del campo Descripción.
  final TextEditingController _descripcionController = TextEditingController();

  /// Fecha seleccionada.
  DateTime _fechaSeleccionada = DateTime.now();

  /// Categoría seleccionada.
  int? _categoriaSeleccionada;

  /// Categorías disponibles.
  final Map<int, String> _categorias = {
    1: 'Mercado',
    2: 'Transporte',
    3: 'Alimentación',
    4: 'Salud',
    5: 'Educación',
    6: 'Entretenimiento',
    7: 'Otros',
  };

  /// Detecta si está activo el tema de alto contraste.
  bool _isHighContrast(BuildContext context) {
    return Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);
  }

  /// Formatea el monto para mostrarlo con separador de miles.
  String _formatAmount(double value) {
    return NumberFormat('#,##0', 'es_CO').format(value);
  }

  /// Construye el estilo de los campos del formulario.
  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? prefix,
    bool highContrast = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefix: prefix,
      filled: highContrast,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: highContrast ? Colors.black : Colors.grey,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: highContrast ? Colors.black : Colors.grey,
          width: highContrast ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: highContrast
              ? const Color(0xFF003B8E)
              : Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      labelStyle: TextStyle(color: highContrast ? Colors.black : null),
      hintStyle: TextStyle(color: highContrast ? Colors.black54 : null),
    );
  }

  /// Guarda un nuevo gasto o actualiza uno existente.
  Future<void> _guardarGasto() async {
    // Valida todos los campos del formulario.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Obtiene el usuario autenticado.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final usuario = authProvider.currentUser;

    // Verifica que exista un usuario autenticado.
    if (usuario == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario no autenticado')));
      return;
    }

    // Convierte el monto mostrado con separadores de miles.
    final textoMonto = _montoController.text
        .trim()
        .replaceAll('\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    final monto = double.tryParse(textoMonto);

    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un monto válido mayor que cero')),
      );
      return;
    }

    final expense = ExpenseModel(
      nombre: _nombreController.text.trim(),
      monto: monto,
      fecha: _fechaSeleccionada.toIso8601String(),
      descripcion: _descripcionController.text.trim(),
      idCategoria: _categoriaSeleccionada!,
      idUsuario: usuario.idUsuario!,
      origen: 'MANUAL',
      fechaRegistro: DateTime.now().toIso8601String(),
    );

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    bool success;

    // Si existe un gasto significa que estamos editando.
    if (widget.expense != null) {
      success = await expenseProvider.updateExpense(
        expense.copyWith(idGasto: widget.expense!.idGasto),
      );
    } else {
      success = await expenseProvider.createExpense(expense);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto registrado correctamente')),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(expenseProvider.errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool highContrast = _isHighContrast(context);

    final Color textColor = highContrast
        ? Colors.black
        : const Color(0xFF17324D);

    final Color primaryColor = highContrast
        ? const Color(0xFF003B8E)
        : const Color(0xFF4380E5);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.expense != null ? 'Editar gasto' : 'Registrar gasto',
        ),
        backgroundColor: highContrast ? Colors.white : null,
        foregroundColor: highContrast ? Colors.black : null,
        elevation: highContrast ? 0 : null,
        shape: highContrast
            ? const Border(bottom: BorderSide(color: Colors.black, width: 2))
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo Nombre.
              Text('Nombre', style: TextStyle(color: textColor)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(
                  label: 'Nombre del gasto',
                  hint: 'Ejemplo: Supermercado',
                  highContrast: highContrast,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese un nombre';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Campo Monto.
              Text('Monto', style: TextStyle(color: textColor)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _montoController,
                style: TextStyle(color: textColor),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  label: 'Monto',
                  hint: 'Ejemplo: 120000',
                  prefix: const Text('\$ '),
                  highContrast: highContrast,
                ),
                validator: (value) {
                  // Verifica que exista un valor.
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese un monto';
                  }

                  // Intenta convertir el texto a número.
                  final monto = double.tryParse(value);

                  if (monto == null) {
                    return 'Ingrese un número válido';
                  }

                  // RN12: El monto debe ser mayor que cero.
                  if (monto <= 0) {
                    return 'El monto debe ser mayor que cero';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Selector de categoría.
              Text('Categoría', style: TextStyle(color: textColor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _categoriaSeleccionada,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(
                  label: 'Categoría',
                  highContrast: highContrast,
                ),
                hint: Text(
                  'Seleccione una categoría',
                  style: TextStyle(color: highContrast ? Colors.black54 : null),
                ),
                items: _categorias.entries.map((categoria) {
                  return DropdownMenuItem<int>(
                    value: categoria.key,
                    child: Text(
                      categoria.value,
                      style: TextStyle(color: textColor),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Seleccione una categoría';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Selector de fecha.
              Text('Fecha', style: TextStyle(color: textColor)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  // Abre el calendario adaptado al tema.
                  final DateTime? fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaSeleccionada,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      if (!highContrast) return child!;

                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: const Color(0xFF003B8E),
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  // Si el usuario seleccionó una fecha.
                  if (fecha != null) {
                    setState(() {
                      _fechaSeleccionada = fecha;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: highContrast ? Colors.black : Colors.grey,
                      width: highContrast ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, color: primaryColor),
                      const SizedBox(width: 10),
                      Text(
                        '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/'
                        '${_fechaSeleccionada.month.toString().padLeft(2, '0')}/'
                        '${_fechaSeleccionada.year}',
                        style: TextStyle(color: textColor),
                      ),
                      const Spacer(),
                      Icon(Icons.edit_calendar_outlined, color: primaryColor),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Campo Descripción.
              Text('Descripción', style: TextStyle(color: textColor)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration(
                  label: 'Descripción',
                  hint: 'Información adicional (opcional)',
                  highContrast: highContrast,
                ),
              ),

              const SizedBox(height: 24),

              // Botón principal para guardar el gasto.
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _guardarGasto,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    widget.expense != null
                        ? 'Actualizar gasto'
                        : 'Guardar gasto',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: highContrast ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: highContrast
                          ? const BorderSide(color: Colors.black, width: 1)
                          : BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    // Si existe un gasto significa que estamos editando.
    if (widget.expense != null) {
      _nombreController.text = widget.expense!.nombre;

      _montoController.text = _formatAmount(widget.expense!.monto);

      _descripcionController.text = widget.expense!.descripcion;

      _fechaSeleccionada = DateTime.parse(widget.expense!.fecha);

      _categoriaSeleccionada = widget.expense!.idCategoria;
    }
  }

  @override
  void dispose() {
    // Libera los controladores al cerrar la pantalla.
    _nombreController.dispose();
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
