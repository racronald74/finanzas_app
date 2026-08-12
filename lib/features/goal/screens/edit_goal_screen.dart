import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/goal_model.dart';
import '../../../providers/goal_provider.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';

/// Pantalla para editar una meta existente.
class EditGoalScreen extends StatefulWidget {
  const EditGoalScreen({super.key, required this.goal});

  /// Meta que se desea editar.
  final GoalModel goal;

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  /// Controlador del nombre.
  final TextEditingController _nameController = TextEditingController();

  /// Controlador del monto objetivo.
  final TextEditingController _targetAmountController = TextEditingController();

  /// Controlador de la fecha límite.
  final TextEditingController _deadlineController = TextEditingController();

  /// Categoría seleccionada.
  late String _selectedCategory;

  /// Prioridad seleccionada.
  late String _selectedPriority;

  /// Estado del recordatorio.
  late bool _reminderEnabled;

  @override
  void initState() {
    super.initState();

    // Carga los valores actuales de la meta.
    _nameController.text = widget.goal.name;
    _targetAmountController.text = widget.goal.targetAmount.toStringAsFixed(0);

    _deadlineController.text = _formatDeadline(widget.goal.deadline);

    _selectedCategory = widget.goal.category;
    _selectedPriority = widget.goal.priority;
    _reminderEnabled = widget.goal.reminderEnabled;
  }

  /// Abre el selector de fecha.
  Future<void> _selectDeadline() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: widget.goal.deadline.isAfter(DateTime.now())
          ? widget.goal.deadline
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    _deadlineController.text = _formatDeadline(selectedDate);
  }

  /// Convierte la fecha visual del formulario a DateTime.
  DateTime? _parseDeadline() {
    final String dateText = _deadlineController.text.trim();

    if (dateText.isEmpty) {
      return null;
    }

    final List<String> parts = dateText.split('/');

    if (parts.length != 3) {
      return null;
    }

    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    final DateTime date = DateTime(year, month, day);

    // Evita aceptar fechas inexistentes como 31/02.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    return date;
  }

  /// Construye la meta actualizada.
  GoalModel? _buildGoal() {
    final double? targetAmount = double.tryParse(
      _targetAmountController.text.trim(),
    );

    if (targetAmount == null) {
      _showError('El monto objetivo no es válido.');
      return null;
    }

    final DateTime? deadline = _parseDeadline();

    if (deadline == null) {
      _showError('La fecha límite no es válida.');
      return null;
    }

    return GoalModel(
      id: widget.goal.id,
      name: _nameController.text.trim(),
      category: _selectedCategory,
      targetAmount: targetAmount,
      savedAmount: widget.goal.savedAmount,
      deadline: deadline,
      status: widget.goal.savedAmount >= targetAmount ? 'Completada' : 'Activa',
      priority: _selectedPriority,
      reminderEnabled: _reminderEnabled,
      userId: widget.goal.userId,
      completedAt: widget.goal.savedAmount >= targetAmount
          ? (widget.goal.completedAt ?? DateTime.now())
          : null,
      createdAt: widget.goal.createdAt,
    );
  }

  /// Guarda los cambios de la meta.
  Future<void> _updateGoal() async {
    if (!_validateForm()) {
      return;
    }

    final GoalModel? updatedGoal = _buildGoal();

    if (updatedGoal == null) {
      return;
    }

    final GoalProvider goalProvider = context.read<GoalProvider>();

    final bool success = await goalProvider.updateGoal(updatedGoal);

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta actualizada correctamente.')),
      );

      Navigator.pop(context, true);
    } else {
      _showError(goalProvider.errorMessage ?? 'No se pudo actualizar la meta.');
    }
  }

  /// Valida los datos del formulario.
  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      _showError('El nombre de la meta es obligatorio.');
      return false;
    }

    final double? targetAmount = double.tryParse(
      _targetAmountController.text.trim(),
    );

    if (targetAmount == null || targetAmount <= 0) {
      _showError('El monto objetivo debe ser mayor que cero.');
      return false;
    }

    // El nuevo objetivo no puede ser inferior
    // al dinero que ya se ha ahorrado.
    if (targetAmount < widget.goal.savedAmount) {
      _showError(
        'El monto objetivo no puede ser menor que '
        'el monto acumulado.',
      );
      return false;
    }

    final DateTime? deadline = _parseDeadline();

    if (deadline == null) {
      _showError('La fecha límite es obligatoria.');
      return false;
    }

    if (!deadline.isAfter(DateTime.now())) {
      _showError('La fecha límite debe ser posterior a la fecha actual.');
      return false;
    }

    return true;
  }

  /// Muestra un mensaje de error.
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Formatea una fecha como dd/MM/yyyy.
  String _formatDeadline(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'Editar meta', showBackButton: true),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nombre de la meta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    CustomTextField(
                      controller: _nameController,
                      label: 'Nombre de la meta',
                      hintText: 'Ej. Viaje a Cartagena',
                      prefixIcon: const Icon(Icons.flag_outlined),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Categoría',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _CategoryChip(
                          icon: Icons.beach_access,
                          label: 'Viajes',
                          selected: _selectedCategory == 'Viajes',
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Viajes';
                            });
                          },
                        ),
                        _CategoryChip(
                          icon: Icons.home,
                          label: 'Vivienda',
                          selected: _selectedCategory == 'Vivienda',
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Vivienda';
                            });
                          },
                        ),
                        _CategoryChip(
                          icon: Icons.directions_car,
                          label: 'Vehículo',
                          selected: _selectedCategory == 'Vehículo',
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Vehículo';
                            });
                          },
                        ),
                        _CategoryChip(
                          icon: Icons.school,
                          label: 'Educación',
                          selected: _selectedCategory == 'Educación',
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Educación';
                            });
                          },
                        ),
                        _CategoryChip(
                          icon: Icons.laptop_mac,
                          label: 'Tecnología',
                          selected: _selectedCategory == 'Tecnología',
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Tecnología';
                            });
                          },
                        ),
                        _CategoryChip(
                          icon: Icons.favorite,
                          label: 'Salud',
                          selected: _selectedCategory == 'Salud',
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Salud';
                            });
                          },
                        ),
                        _CategoryChip(
                          icon: Icons.more_horiz,
                          label: 'Otra',
                          selected: _selectedCategory == 'Otra',
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Otra';
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Prioridad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 10,
                      children: [
                        _PriorityChip(
                          label: 'Baja',
                          selected: _selectedPriority == 'Baja',
                          onTap: () {
                            setState(() {
                              _selectedPriority = 'Baja';
                            });
                          },
                        ),
                        _PriorityChip(
                          label: 'Media',
                          selected: _selectedPriority == 'Media',
                          onTap: () {
                            setState(() {
                              _selectedPriority = 'Media';
                            });
                          },
                        ),
                        _PriorityChip(
                          label: 'Alta',
                          selected: _selectedPriority == 'Alta',
                          onTap: () {
                            setState(() {
                              _selectedPriority = 'Alta';
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _targetAmountController,
                      label: 'Monto objetivo',
                      hintText: 'Ej. \$2.000.000',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.attach_money),
                    ),

                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _deadlineController,
                      label: 'Fecha límite',
                      hintText: 'Seleccione una fecha',
                      readOnly: true,
                      onTap: _selectDeadline,
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),

                    const SizedBox(height: 24),

                    // El monto acumulado se muestra como
                    // información, pero no se modifica aquí.
                    const Text(
                      'Monto acumulado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    CustomTextField(
                      controller: TextEditingController(
                        text: widget.goal.savedAmount.toStringAsFixed(0),
                      ),
                      label: 'Monto acumulado',
                      readOnly: true,
                      prefixIcon: const Icon(Icons.savings_outlined),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recordatorio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: _reminderEnabled,
                          onChanged: (value) {
                            setState(() {
                              _reminderEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Guardar cambios',
                      icon: Icons.save_outlined,
                      onPressed: _updateGoal,
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }
}

/// Chip para seleccionar una categoría.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : null),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

/// Chip para seleccionar la prioridad.
class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
