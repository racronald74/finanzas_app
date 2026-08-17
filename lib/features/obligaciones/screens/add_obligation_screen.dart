import '../../../data/repositories/category_repository.dart';
import '../../../data/models/category_model.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../data/models/obligation_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/obligation_provider.dart';
import '../../../data/services/obligation_service.dart';

/// Pantalla para registrar o editar una obligación.
///
/// Si [initialObligation] es null, se utiliza para registrar
/// una nueva obligación.
///
/// Si contiene una obligación, se utiliza para editarla.
class AddObligationScreen extends StatefulWidget {
  /// Obligación existente cuando la pantalla se utiliza
  /// para editar.
  ///
  /// Si es null, la pantalla funciona como registro nuevo.
  final ObligationModel? initialObligation;

  const AddObligationScreen({super.key, this.initialObligation});

  @override
  State<AddObligationScreen> createState() => _AddObligationScreenState();
}

class _AddObligationScreenState extends State<AddObligationScreen> {
  /// Indica si se está guardando una obligación.
  bool _isSaving = false;

  /// Indica si la pantalla está editando una obligación existente.
  bool get _isEditing => widget.initialObligation != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    // Selector entre obligación fija y variable.
                    _buildObligationForm(),

                    const SizedBox(height: 16),

                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Encabezado de la pantalla.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: const Color(0xFF3F73BC),
      child: Row(
        children: [
          /// Regreso a la pantalla anterior.
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),

          const SizedBox(width: 2),

          Expanded(
            child: Text(
              _isEditing ? 'Editar Obligación' : 'Agregar Obligación',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          /// Avatar utilizado en el prototipo.
          const CircleAvatar(radius: 22, child: Icon(Icons.person, size: 26)),
        ],
      ),
    );
  }

  /// Controlador para el nombre de la obligación.
  final TextEditingController _nombreController = TextEditingController();

  /// Controlador para el monto de la obligación.
  final TextEditingController _montoController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  /// Repositorio utilizado para consultar categorías.
  final CategoryRepository _categoryRepository = CategoryRepository();

  /// Categorías disponibles para obligaciones.
  List<CategoryModel> _categories = [];

  /// Categoría seleccionada.
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();

    _loadCategories();

    final obligation = widget.initialObligation;

    if (obligation != null) {
      // Datos generales.
      _nombreController.text = obligation.nombre;
      _montoController.text = obligation.monto.toStringAsFixed(0);

      // Categoría.
      _selectedCategoryId = obligation.idCategoria;

      // Configuración de la obligación.
      _frecuenciaSeleccionada = obligation.frecuencia;

      // Carga la fecha de vencimiento existente.
      _fechaVencimiento = DateTime.tryParse(obligation.fechaVencimiento);
    }
  }

  /// Obtiene las categorías destinadas a obligaciones.
  Future<void> _loadCategories() async {
    final categories = await _categoryRepository.getCategoriesByType(
      'OBLIGACION',
    );

    if (!mounted) return;

    setState(() {
      _categories = categories;
    });
  }

  /// Construye el formulario único para registrar
  /// o editar una obligación.
  ///
  /// La frecuencia determina si la obligación
  /// es única o recurrente.
  Widget _buildObligationForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _nombreController,
          icon: Icons.home_outlined,
          label: 'Nombre de la obligación',
          hint: 'Ej: Arriendo, Netflix, Inscripción',
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _montoController,
                icon: Icons.attach_money,
                label: 'Monto',
                hint: '\$0',
                keyboardType: TextInputType.number,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildDateField(
                icon: Icons.calendar_today_outlined,
                title: 'Fecha de vencimiento',
                value: _fechaVencimiento == null
                    ? 'Seleccionar fecha'
                    : _formatDate(_fechaVencimiento!),
                onTap: _selectDueDate,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        _buildCategoryField(),

        const SizedBox(height: 10),

        _buildDropdownField(
          icon: Icons.refresh_outlined,
          title: 'Frecuencia',
          value: _frecuenciaSeleccionada,
          hint: 'Seleccionar frecuencia',
          items: const [
            'Ninguna',
            'Mensual',
            'Trimestral',
            'Semestral',
            'Anual',
          ],
          onChanged: (value) {
            setState(() {
              _frecuenciaSeleccionada = value;
            });
          },
        ),

        const SizedBox(height: 10),

        _buildReminderField(),
      ],
    );
  }

  /// Botón utilizado para registrar una nueva obligación.
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _guardarObligacion,
        icon: const Icon(Icons.save_outlined),
        label: const Text(
          'Guardar obligación',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4380E5),
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
    );
  }

  /// Botones principales del formulario.
  ///
  /// En modo registro muestra únicamente Guardar obligación.
  /// En modo edición muestra Guardar cambios, Eliminar obligación
  /// y Cancelar.
  Widget _buildActionButtons() {
    if (!_isEditing) {
      return _buildSaveButton();
    }

    return Column(
      children: [
        // Guardar cambios.
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _guardarObligacion,
            icon: const Icon(Icons.save_outlined),
            label: const Text(
              'Guardar cambios',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4380E5),
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Eliminar obligación.
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: _eliminarObligacion,
            icon: const Icon(Icons.delete_outline),
            label: const Text(
              'Eliminar obligación',
              style: TextStyle(fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Cancelar edición.
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text('Cancelar', style: TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }

  /// Elimina la obligación actualmente editada.
  Future<void> _eliminarObligacion() async {
    final obligation = widget.initialObligation;

    if (obligation == null || obligation.idObligacion == null) {
      return;
    }

    final provider = Provider.of<ObligationProvider>(context, listen: false);

    await provider.deleteObligation(
      obligation.idObligacion!,
      obligation.idUsuario,
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  /// Campo de texto reutilizable para el formulario.
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD5E1ED)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  /// Campo utilizado para seleccionar una categoría de obligación.
  Widget _buildCategoryField() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD5E1ED)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCategoryId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          hint: Row(
            children: [
              Icon(Icons.folder_outlined, color: Colors.grey.shade600),
              const SizedBox(width: 10),
              const Text(
                'Seleccionar categoría',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<int>(
              value: category.idCategoria,
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  Text(
                    category.nombre,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
        ),
      ),
    );
  }

  /// Campo visual utilizado para seleccionar fechas o días.
  Widget _buildDateField({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFD5E1ED)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          value == 'Seleccionar fecha' ||
                              value == 'Seleccionar día'
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  /// Fecha de vencimiento de una obligación variable.
  DateTime? _fechaVencimiento;

  /// Selecciona la fecha de vencimiento de una obligación variable.
  Future<void> _selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;

    setState(() {
      _fechaVencimiento = selectedDate;
    });
  }

  /// Convierte una fecha a formato YYYY-MM-DD.
  ///
  /// Este es el formato utilizado actualmente
  /// por los modelos de la aplicación.
  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  /// Frecuencia seleccionada para una obligación fija.
  String? _frecuenciaSeleccionada;

  /// Indica si la obligación tiene recordatorio activo.
  bool _recordatorio = false;

  /// Selector reutilizable para opciones del formulario.
  Widget _buildDropdownField({
    required IconData icon,
    required String title,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD5E1ED)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text(
                  hint,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Campo para activar o desactivar el recordatorio.
  Widget _buildReminderField() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD5E1ED)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none_outlined, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Recordatorio',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Switch(
            value: _recordatorio,
            onChanged: (value) {
              setState(() {
                _recordatorio = value;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Guarda una nueva obligación o actualiza una existente.
  ///
  /// La frecuencia determina si la obligación es única
  /// o recurrente:
  ///
  /// - Ninguna: obligación de un solo uso.
  /// - Cualquier otra frecuencia: obligación recurrente.
  Future<void> _guardarObligacion() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });
    final nombre = _nombreController.text.trim();

    final monto = double.tryParse(_montoController.text.trim());

    // Valida el nombre.
    if (nombre.isEmpty) {
      _showMessage('Ingrese un nombre para la obligación');
      return;
    }

    // Valida el monto.
    if (monto == null || monto <= 0) {
      _showMessage('Ingrese un monto válido mayor que cero');
      return;
    }

    // Valida la categoría.
    if (_selectedCategoryId == null) {
      _showMessage('Seleccione una categoría');
      return;
    }

    // Valida la fecha de vencimiento.
    if (_fechaVencimiento == null) {
      _showMessage('Seleccione la fecha de vencimiento');
      return;
    }

    // Valida la frecuencia.
    if (_frecuenciaSeleccionada == null) {
      _showMessage('Seleccione la frecuencia');
      return;
    }

    // Obtiene el usuario autenticado.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final usuario = authProvider.currentUser;

    if (usuario == null || usuario.idUsuario == null) {
      _showMessage('Usuario no autenticado');
      return;
    }

    // Determina si la obligación será recurrente.
    final bool esRecurrente = _frecuenciaSeleccionada != 'Ninguna';

    // Construye el modelo de obligación.
    final obligation = ObligationModel(
      idObligacion: widget.initialObligation?.idObligacion,
      nombre: nombre,
      monto: monto,
      idCategoria: _selectedCategoryId!,
      fechaVencimiento: _formatDate(_fechaVencimiento!),
      recordatorio: _recordatorio,
      estado: ObligationService.estadoPendiente,
      esRecurrente: esRecurrente,
      diaVencimiento: esRecurrente ? _fechaVencimiento!.day : null,
      idUsuario: usuario.idUsuario!,
      idGastoGenerado: null,
      fechaRegistro: DateTime.now().toIso8601String(),
      frecuencia: _frecuenciaSeleccionada,
    );

    final obligationProvider = Provider.of<ObligationProvider>(
      context,
      listen: false,
    );

    bool success;

    try {
      success = _isEditing
          ? await obligationProvider.updateObligation(obligation)
          : await obligationProvider.createObligation(obligation);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }

    if (!mounted) return;

    if (!success) {
      _showMessage(obligationProvider.errorMessage);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Obligación actualizada correctamente'
              : 'Obligación registrada correctamente',
        ),
      ),
    );

    Navigator.pop(context);
  }

  /// Muestra un mensaje al usuario.
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
