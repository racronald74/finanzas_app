import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();

    final income = widget.initialIncome;
    if (income != null) {
      _montoController.text = income.monto.toStringAsFixed(0);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar ingreso' : 'Agregar ingreso'),
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
              decoration: const InputDecoration(labelText: 'Monto'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
              ),
              leading: const Icon(Icons.calendar_month),
              onTap: () async {
                final fecha = await showDatePicker(
                  context: context,
                  initialDate: _fechaSeleccionada,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (fecha != null) {
                  setState(() {
                    _fechaSeleccionada = fecha;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _categoriaSeleccionada,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: _categorias.map((categoria) {
                return DropdownMenuItem<String>(
                  value: categoria.idCategoria.toString(),
                  child: Text(categoria.nombre),
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
              decoration: const InputDecoration(
                labelText: 'Descripcion (opcional)',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveIncome,
                child: Text(_isEditing ? 'Guardar cambios' : 'Guardar ingreso'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveIncome() async {
    final monto = double.tryParse(_montoController.text.trim());

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
