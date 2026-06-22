// Librería principal de Flutter para construir interfaces
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';

import '../../../data/models/expense_model.dart';

/// Pantalla para registrar o editar un gasto.
///
/// Esta pantalla será reutilizable:
///
/// - Registrar gasto
/// - Editar gasto
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  /// Llave del formulario.
  ///
  /// Permite validar todos los campos del formulario
  /// con una sola instrucción.
  final _formKey = GlobalKey<FormState>();

  /// Controlador del campo Nombre.
  final TextEditingController _nombreController = TextEditingController();

  /// Controlador del campo Monto.
  final TextEditingController _montoController = TextEditingController();

  /// Controlador del campo Descripción.
  final TextEditingController _descripcionController = TextEditingController();

  /// Fecha seleccionada.
  ///
  /// Por defecto será la fecha actual.
  DateTime _fechaSeleccionada = DateTime.now();

  /// Categoría seleccionada.
  int? _categoriaSeleccionada;

  /// Categorías disponibles.
  ///
  /// Temporalmente se encuentran en memoria.
  /// Más adelante se cargarán desde SQLite.
  final Map<int, String> _categorias = {
    1: 'Mercado',

    2: 'Transporte',

    3: 'Alimentación',

    4: 'Salud',

    5: 'Educación',

    6: 'Entretenimiento',

    7: 'Otros',
  };

  /// Guarda un nuevo gasto.
  ///
  /// Valida el formulario, construye el modelo,
  /// llama al Provider y regresa a la pantalla
  /// anterior cuando la operación es exitosa.
  Future<void> _guardarGasto() async {
    print("1 - Entró al método");

    // Valida todos los campos del formulario.
    if (!_formKey.currentState!.validate()) {
      print("2 - Formulario inválido");

      return;
    }

    print("3 - Formulario válido");

    // Obtiene el usuario autenticado.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final usuario = authProvider.currentUser;

    print("4 - Usuario: $usuario");

    // Verifica que exista un usuario autenticado.
    if (usuario == null) {
      print("5 - Usuario no autenticado");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario no autenticado')));

      return;
    }

    print("6 - Construyendo ExpenseModel");

    final expense = ExpenseModel(
      nombre: _nombreController.text.trim(),
      monto: double.parse(_montoController.text),
      fecha: _fechaSeleccionada.toIso8601String(),
      descripcion: _descripcionController.text.trim(),
      idCategoria: _categoriaSeleccionada!,
      idUsuario: usuario.idUsuario!,
      origen: 'MANUAL',
      fechaRegistro: DateTime.now().toIso8601String(),
    );

    print("7 - ExpenseModel construido");

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    print("8 - Antes de createExpense");

    final success = await expenseProvider.createExpense(expense);

    print("9 - Resultado: $success");

    if (!mounted) return;

    if (success) {
      print("10 - Registro exitoso");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto registrado correctamente')),
      );

      Navigator.pop(context);
    } else {
      print("11 - Error: ${expenseProvider.errorMessage}");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(expenseProvider.errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar gasto')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Aquí agregaremos los campos del formulario.
            children: [
              // Campo Nombre
              const Text('Nombre'),

              SizedBox(height: 8),

              TextFormField(
                controller: _nombreController,

                decoration: const InputDecoration(
                  hintText: 'Ejemplo: Supermercado',

                  border: OutlineInputBorder(),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese un nombre';
                  }

                  return null;
                },
              ),
              // Espacio entre campos
              const SizedBox(height: 16),
              // Campo Monto
              const Text('Monto'),
              // Espacio entre etiqueta y campo
              const SizedBox(height: 8),
              // Campo de texto para el monto
              TextFormField(
                controller: _montoController,
                // Configura el teclado para números decimales
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                // Decoración del campo
                decoration: const InputDecoration(
                  hintText: 'Ejemplo: 120000',
                  // Borde del campo
                  border: OutlineInputBorder(),
                ),
                // Validación del campo
                validator: (value) {
                  // Verifica que exista un valor.
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese un monto';
                  }
                  // Intenta convertir el texto a número.
                  // Convierte el texto a número.
                  final monto = double.tryParse(value);

                  // Si no es un número válido.
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

              const Text('Categoría'),

              const SizedBox(height: 8),
              // Campo de selección de categoría
              DropdownButtonFormField<int>(
                initialValue: _categoriaSeleccionada,

                decoration: const InputDecoration(border: OutlineInputBorder()),

                hint: const Text('Seleccione una categoría'),

                items: _categorias.entries.map((categoria) {
                  return DropdownMenuItem<int>(
                    value: categoria.key,

                    child: Text(categoria.value),
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

              const Text('Fecha'),

              const SizedBox(height: 8),
              // Campo de selección de fecha
              InkWell(
                onTap: () async {
                  // Abre el calendario.
                  final DateTime? fecha = await showDatePicker(
                    context: context,

                    initialDate: _fechaSeleccionada,

                    firstDate: DateTime(2020),

                    lastDate: DateTime(2100),
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
                    border: Border.all(color: Colors.grey),

                    borderRadius: BorderRadius.circular(4),
                  ),

                  child: Text(
                    '${_fechaSeleccionada.day.toString().padLeft(2, '0')}/'
                    '${_fechaSeleccionada.month.toString().padLeft(2, '0')}/'
                    '${_fechaSeleccionada.year}',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text('Descripción'),

              const SizedBox(height: 8),
              // Campo de texto para la descripción
              TextFormField(
                controller: _descripcionController,

                maxLines: 3,

                decoration: const InputDecoration(
                  hintText: 'Información adicional (opcional)',

                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),
              // Botón para guardar el gasto
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: _guardarGasto,

                  child: const Text('Guardar gasto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
