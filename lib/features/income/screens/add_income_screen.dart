import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/models/category_model.dart';
import '../../../data/models/income_model.dart';
import '../../../data/services/category_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/income_provider.dart';

// Pantalla para agregar o editar un ingreso en la aplicación.
class AddIncomeScreen extends StatefulWidget {
  final IncomeModel? initialIncome;

  const AddIncomeScreen({super.key, this.initialIncome});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final CategoryService _categoryService = CategoryService();

  DateTime _fechaSeleccionada = DateTime.now();
  String? _categoriaSeleccionada;
  List<CategoryModel> _categorias = [];

  bool get _isEditing => widget.initialIncome != null;

  // Detecta si está activo el tema de alto contraste.
  bool get _highContrast =>
      Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);

  @override
  void initState() {
    super.initState();

    final income = widget.initialIncome;
    if (income != null) {
      _montoController.text = _formatAmount(income.monto);
      _descripcionController.text = income.descripcion;
      _fechaSeleccionada = DateTime.tryParse(income.fecha) ?? DateTime.now();
      _categoriaSeleccionada = income.idCategoria?.toString();
    }

    _loadCategories();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categorias = await _categoryService.getCategoriesByType('INGRESO');

    if (!mounted) return;

    setState(() {
      _categorias = categorias;
    });
  }

  @override
  Widget build(BuildContext context) {
    final highContrast = _highContrast;
    final textColor = highContrast ? Colors.black : null;
    // Define el color del borde según el modo de visualización.
    final borderColor = highContrast ? Colors.black : const Color(0xFF666666);

    // Define el estilo de los campos sin alterar sus valores ni validaciones.
    final inputDecoration = InputDecoration(
      labelStyle: TextStyle(color: textColor),
      prefixStyle: TextStyle(color: textColor),
      enabledBorder: highContrast
          ? const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            )
          : null,
      focusedBorder: highContrast
          ? const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF003B8E), width: 2),
            )
          : null,
      border: highContrast
          ? const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            )
          : null,
    );

    return Scaffold(
      backgroundColor: highContrast ? Colors.white : null,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar ingreso' : 'Agregar ingreso'),
        backgroundColor: highContrast ? Colors.white : null,
        foregroundColor: highContrast ? Colors.black : null,
        elevation: highContrast ? 0 : null,
        bottom: highContrast
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: Divider(height: 2, thickness: 2, color: Colors.black),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(color: textColor),
              decoration: inputDecoration.copyWith(
                labelText: 'Monto',
                prefixText: r'$',
              ),
            ),
            const SizedBox(height: 16),

            // Permite seleccionar la fecha del ingreso.
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  // Reutiliza el color definido para ambos modos.
                  color: borderColor,
                  width: highContrast ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListTile(
                textColor: textColor,
                title: Text(
                  '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                ),
                leading: Icon(
                  Icons.calendar_month,
                  color: highContrast ? const Color(0xFF003B8E) : null,
                ),
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaSeleccionada,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
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

                  if (fecha != null) {
                    setState(() {
                      _fechaSeleccionada = fecha;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Selector de categorías de ingreso.
            DropdownButtonFormField<String>(
              initialValue: _categoriaSeleccionada,

              // Fondo blanco en modo normal y contraste.
              dropdownColor: Colors.white,

              // Texto oscuro en modo normal y contraste.
              style: const TextStyle(color: Colors.black),

              decoration: inputDecoration.copyWith(labelText: 'Categoria'),

              items: _categorias.map((categoria) {
                return DropdownMenuItem<String>(
                  value: categoria.idCategoria.toString(),
                  child: Text(
                    categoria.nombre,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),

              onChanged: (value) {
                setState(() {
                  _categoriaSeleccionada = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _descripcionController,
              style: TextStyle(color: textColor),
              decoration: inputDecoration.copyWith(
                labelText: 'Descripcion (opcional)',
              ),
            ),
            const SizedBox(height: 32),

            // Botón principal para guardar el ingreso.
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _saveIncome,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _isEditing ? 'Guardar cambios' : 'Guardar ingreso',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: highContrast
                      ? const Color(0xFF003B8E)
                      : const Color(0xFF4380E5),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveIncome() async {
    // Convierte el monto mostrado con separadores
    // de miles al valor numérico utilizado por la aplicación.
    final textoMonto = _montoController.text
        .trim()
        .replaceAll('\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    final monto = double.tryParse(textoMonto);

    if (monto == null || monto <= 0) {
      _showMessage('Ingrese un monto valido mayor a cero');
      return;
    }

    if (_categoriaSeleccionada == null) {
      _showMessage('Seleccione una categoria');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) {
      _showMessage('Usuario no autenticado');
      return;
    }

    final categoria = _categorias.firstWhere(
      (c) => c.idCategoria.toString() == _categoriaSeleccionada,
    );

    final income = IncomeModel(
      idIngreso: widget.initialIncome?.idIngreso,
      descripcion: _descripcionController.text.trim(),
      monto: monto,
      fecha: _fechaSeleccionada.toIso8601String(),
      tipo: widget.initialIncome?.tipo ?? 'ADICIONAL',
      fuente: categoria.nombre,
      origen: widget.initialIncome?.origen ?? 'Manual',
      idCategoria: categoria.idCategoria,
      idUsuario: user.idUsuario!,
      fechaRegistro: widget.initialIncome?.fechaRegistro,
    );

    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    final success = _isEditing
        ? await incomeProvider.updateIncome(income)
        : await incomeProvider.createIncome(income);

    if (!mounted) return;

    if (!success) {
      _showMessage(incomeProvider.errorMessage ?? 'No fue posible guardar');
      return;
    }

    _showMessage(
      _isEditing
          ? 'Ingreso actualizado correctamente'
          : 'Ingreso registrado correctamente',
    );
    Navigator.pop(context);
  }

  // Muestra mensajes de validación y resultado.
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Formatea el monto para mostrarlo con separador de miles.
  String _formatAmount(double value) {
    return NumberFormat('#,##0', 'es_CO').format(value);
  }
}
