import 'package:flutter/material.dart';

import '../../../data/services/category_service.dart';
import '../../../data/models/category_model.dart';

import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/income_provider.dart';

import '../../../data/models/income_model.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  // Controlador monto
  final TextEditingController _montoController = TextEditingController();

  // Controlador descripción
  final TextEditingController _descripcionController = TextEditingController();

  // Fecha seleccionada
  DateTime _fechaSeleccionada = DateTime.now();

  // Categoría seleccionada
  String? _categoriaSeleccionada;

  /// Servicio de categorías
  final CategoryService _categoryService = CategoryService();

  /// Categorías cargadas desde SQLite
  List<CategoryModel> _categorias = [];

  /// Cargar categorías de ingreso
  Future<void> _loadCategories() async {
    final categorias = await _categoryService.getCategoriesByType('INGRESO');

    setState(() {
      _categorias = categorias;
    });
  }

  @override
  void initState() {
    super.initState();

    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar ingreso')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // MONTO
            TextField(
              controller: _montoController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(labelText: 'Monto'),
            ),

            const SizedBox(height: 16),

            // FECHA
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

            // CATEGORIA
            DropdownButtonFormField<String>(
              initialValue: _categoriaSeleccionada,

              decoration: const InputDecoration(labelText: 'Categoría'),

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

            // DESCRIPCIÓN
            TextField(
              controller: _descripcionController,

              decoration: const InputDecoration(
                labelText: 'Descripción (Opcional)',
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () async {
                  // Validar monto
                  if (_montoController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingrese un monto')),
                    );

                    return;
                  }

                  // Validar categoría
                  if (_categoriaSeleccionada == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seleccione una categoría')),
                    );

                    return;
                  }

                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );

                  final user = authProvider.currentUser;

                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Usuario no autenticado')),
                    );

                    return;
                  }

                  final income = IncomeModel(
                    descripcion: _descripcionController.text.trim(),

                    monto: double.parse(_montoController.text),

                    fecha: _fechaSeleccionada.toIso8601String(),

                    tipo: 'ADICIONAL',

                    idCategoria: int.parse(_categoriaSeleccionada!),

                    idUsuario: user.idUsuario!,
                  );

                  final incomeProvider = Provider.of<IncomeProvider>(
                    context,
                    listen: false,
                  );

                  await incomeProvider.createIncome(income);

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingreso registrado correctamente'),
                    ),
                  );

                  Navigator.pop(context);
                },

                child: const Text('Guardar ingreso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
