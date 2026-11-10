import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/category_repository.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/obligation_model.dart';
import '../../../data/services/obligation_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/obligation_provider.dart';

/// Pantalla para registrar o editar una obligación.
///
/// Si initialObligation es null, registra una obligación nueva.
/// Si contiene una obligación, permite editarla.
class AddObligationScreen extends StatefulWidget {
  final ObligationModel? initialObligation;

  const AddObligationScreen({super.key, this.initialObligation});

  @override
  State<AddObligationScreen> createState() => _AddObligationScreenState();
}

class _AddObligationScreenState extends State<AddObligationScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();

  final CategoryRepository _categoryRepository = CategoryRepository();

  bool _isSaving = false;
  bool _recordatorio = false;

  DateTime? _fechaVencimiento;
  String? _frecuenciaSeleccionada;
  int? _selectedCategoryId;

  List<CategoryModel> _categories = [];

  /// Indica si la pantalla está editando una obligación.
  bool get _isEditing => widget.initialObligation != null;

  /// Detecta si está activo el tema de alto contraste.
  bool get _highContrast {
    return Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);
  }

  /// Obtiene el color principal del tema.
  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  /// Color utilizado para los textos.
  Color get _textColor => _highContrast ? Colors.black : Colors.black87;

  /// Color utilizado para los bordes.
  Color get _borderColor =>
      _highContrast ? Colors.black : const Color(0xFFD5E1ED);

  @override
  void initState() {
    super.initState();

    // Carga las categorías disponibles.
    _loadCategories();

    // Recupera los datos cuando se está editando.
    final obligation = widget.initialObligation;

    if (obligation != null) {
      _nombreController.text = obligation.nombre;
      _montoController.text = obligation.monto.toStringAsFixed(0);

      _selectedCategoryId = obligation.idCategoria;
      _frecuenciaSeleccionada = obligation.frecuencia;
      _recordatorio = obligation.recordatorio;

      _fechaVencimiento = DateTime.tryParse(obligation.fechaVencimiento);
    }
  }

  @override
  void dispose() {
    // Libera los controladores de texto.
    _nombreController.dispose();
    _montoController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cambia el fondo cuando está activo el alto contraste.
      backgroundColor: _highContrast ? Colors.white : const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    // Formulario compartido para crear y editar.
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

  /// Construye el encabezado de la pantalla.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: const Color(0xFF3F73BC),
      child: Row(
        children: [
          // Regresa a la pantalla anterior.
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              _isEditing ? 'Editar Obligación' : 'Agregar Obligación',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const CircleAvatar(radius: 22, child: Icon(Icons.person, size: 26)),
        ],
      ),
    );
  }

  /// Construye todos los campos del formulario.
  Widget _buildObligationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nombre de la obligación.
        _buildTextField(
          controller: _nombreController,
          icon: Icons.home_outlined,
          label: 'Nombre de la obligación',
          hint: 'Ej: Arriendo, Netflix, Inscripción',
        ),
        const SizedBox(height: 12),

        // Monto de la obligación.
        _buildTextField(
          controller: _montoController,
          icon: Icons.attach_money,
          label: 'Monto',
          hint: '\$0',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),

        // Fecha de vencimiento.
        _buildDateField(
          icon: Icons.calendar_today_outlined,
          title: 'Fecha de vencimiento',
          value: _fechaVencimiento == null
              ? 'Seleccione fecha'
              : _formatDate(_fechaVencimiento!),
          onTap: _selectDueDate,
        ),
        const SizedBox(height: 12),

        // Categoría.
        _buildCategoryField(),
        const SizedBox(height: 12),

        // Frecuencia.
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
        const SizedBox(height: 12),

        // Recordatorio.
        _buildReminderField(),
      ],
    );
  }

  /// Construye los botones según el modo de la pantalla.
  Widget _buildActionButtons() {
    if (!_isEditing) {
      return _buildSaveButton();
    }

    return Column(
      children: [
        // Guarda los cambios de la obligación.
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _guardarObligacion,
            icon: const Icon(Icons.save_outlined),
            label: const Text(
              'Guardar cambios',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: _primaryButtonStyle(),
          ),
        ),
        const SizedBox(height: 8),

        // Elimina la obligación existente.
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _eliminarObligacion,
            icon: const Icon(Icons.delete_outline),
            label: const Text(
              'Eliminar obligación',
              style: TextStyle(fontSize: 15),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Cancela la edición.
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _highContrast
                  ? Colors.black
                  : Colors.grey.shade600,
              side: BorderSide(
                color: _highContrast ? Colors.black : Colors.grey.shade400,
                width: _highContrast ? 1.5 : 1,
              ),
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

  /// Construye el botón para registrar una nueva obligación.
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _guardarObligacion,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: const Text(
          'Guardar obligación',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: _primaryButtonStyle(),
      ),
    );
  }

  /// Define el estilo compartido de los botones principales.
  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _highContrast ? _primaryColor : const Color(0xFF4380E5),
      foregroundColor: Colors.white,
      elevation: _highContrast ? 0 : 1,
      side: _highContrast
          ? const BorderSide(color: Colors.black, width: 1.5)
          : BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );
  }

  /// Campo de texto reutilizable.
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _borderColor, width: _highContrast ? 1.5 : 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: 1,
        style: TextStyle(color: _textColor),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: _highContrast ? Colors.black : Colors.grey.shade600,
          ),
          labelText: label,
          labelStyle: TextStyle(color: _textColor),
          hintText: hint,
          hintStyle: TextStyle(
            color: _highContrast ? Colors.black54 : Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  /// Campo para seleccionar una categoría.
  Widget _buildCategoryField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _borderColor, width: _highContrast ? 1.5 : 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCategoryId,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: _highContrast ? Colors.black : Colors.grey,
          ),
          hint: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                color: _highContrast ? Colors.black : Colors.grey.shade600,
              ),
              const SizedBox(width: 10),
              Text(
                'Seleccionar categoría',
                style: TextStyle(
                  fontSize: 12,
                  color: _highContrast ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<int>(
              value: category.idCategoria,
              child: Row(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    color: _highContrast ? Colors.black : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      category.nombre,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
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

  /// Campo adaptable para seleccionar una fecha.
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
        constraints: const BoxConstraints(minHeight: 65),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: _borderColor,
            width: _highContrast ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _highContrast ? Colors.black : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    softWrap: true,
                    style: TextStyle(fontSize: 12, color: _textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 13,
                      color: value == 'Seleccione fecha' && !_highContrast
                          ? Colors.grey.shade500
                          : _textColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: _highContrast ? Colors.black : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

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
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _borderColor, width: _highContrast ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _highContrast ? Colors.black : Colors.grey.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.white,
                hint: Text(
                  hint,
                  style: TextStyle(
                    fontSize: 12,
                    color: _highContrast ? Colors.black : Colors.grey,
                  ),
                ),
                items: items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
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
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _borderColor, width: _highContrast ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            color: _highContrast ? Colors.black : Colors.grey.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recordatorio',
              style: TextStyle(fontSize: 12, color: _textColor),
            ),
          ),
          Switch(
            value: _recordatorio,
            activeThumbColor: _highContrast ? Colors.white : null,
            activeTrackColor: _highContrast ? _primaryColor : null,
            inactiveThumbColor: _highContrast ? Colors.black : null,
            inactiveTrackColor: _highContrast ? Colors.white : null,
            trackOutlineColor: _highContrast
                ? WidgetStateProperty.all(Colors.black)
                : null,
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

  /// Selecciona la fecha de vencimiento.
  Future<void> _selectDueDate() async {
    final DateTime now = DateTime.now();
    final bool highContrast = _highContrast;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar fecha de vencimiento',
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
      _fechaVencimiento = selectedDate;
    });
  }

  /// Convierte una fecha a formato YYYY-MM-DD.
  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  /// Guarda una obligación nueva o actualiza una existente.
  Future<void> _guardarObligacion() async {
    if (_isSaving) return;

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

    setState(() {
      _isSaving = true;
    });

    // Determina si la obligación será recurrente.
    final bool esRecurrente = _frecuenciaSeleccionada != 'Ninguna';

    // Recupera la obligación original cuando se está editando.
    final original = widget.initialObligation;

    // Construye el modelo conservando los datos originales.
    final obligation = ObligationModel(
      idObligacion: original?.idObligacion,
      idGrupoRecurrencia: original?.idGrupoRecurrencia,
      recurrenciaActiva: original?.recurrenciaActiva ?? true,
      nombre: nombre,
      monto: monto,
      idCategoria: _selectedCategoryId!,
      fechaVencimiento: _formatDate(_fechaVencimiento!),
      recordatorio: _recordatorio,
      estado: original?.estado ?? ObligationService.estadoPendiente,
      esRecurrente: esRecurrente,
      diaVencimiento: esRecurrente ? _fechaVencimiento!.day : null,
      idUsuario: usuario.idUsuario!,
      idGastoGenerado: original?.idGastoGenerado,
      fechaRegistro:
          original?.fechaRegistro ?? DateTime.now().toIso8601String(),
      frecuencia: _frecuenciaSeleccionada,
    );

    final obligationProvider = Provider.of<ObligationProvider>(
      context,
      listen: false,
    );

    bool success = false;

    try {
      // Ejecuta la operación correspondiente.
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

  /// Elimina la obligación que se está editando.
  Future<void> _eliminarObligacion() async {
    final obligation = widget.initialObligation;

    if (obligation == null || obligation.idObligacion == null) {
      return;
    }

    // Solicita confirmación antes de eliminar.
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: _highContrast
              ? RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          title: const Text('Eliminar obligación'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta obligación?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final provider = Provider.of<ObligationProvider>(context, listen: false);

    await provider.deleteObligation(
      obligation.idObligacion!,
      obligation.idUsuario,
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  /// Muestra mensajes al usuario.
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
