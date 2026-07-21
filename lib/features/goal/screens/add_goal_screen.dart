import 'package:flutter/material.dart';

import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';

/// Pantalla para registrar una nueva meta de ahorro.
///
/// En esta primera versión únicamente se implementa
/// la estructura base de la pantalla. El formulario
/// se irá construyendo progresivamente.
class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  /// Controlador del nombre de la meta.
  final TextEditingController _nameController = TextEditingController();

  /// Controlador del monto objetivo.
  final TextEditingController _targetAmountController = TextEditingController();

  /// Controlador de la fecha límite.
  final TextEditingController _deadlineController = TextEditingController();

  /// Controlador del aporte inicial.
  final TextEditingController _initialAmountController =
      TextEditingController();

  /// Categoría seleccionada.
  String _selectedCategory = 'Viajes';

  /// Abre el selector de fecha.
  Future<void> _selectDeadline() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;

    _deadlineController.text =
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year}';
  }

  @override
  void initState() {
    super.initState();

    final DateTime today = DateTime.now();

    _deadlineController.text =
        '${today.day.toString().padLeft(2, '0')}/'
        '${today.month.toString().padLeft(2, '0')}/'
        '${today.year}';
  }

  ///Metodo build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            /// Encabezado de la pantalla.
            const AppHeader(title: 'Crear meta', showBackButton: true),

            /// Contenido.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Nombre de la meta.
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

                    /// Categoría.
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

                    /// Monto objetivo.
                    CustomTextField(
                      controller: _targetAmountController,
                      label: 'Monto objetivo',
                      hintText: 'Ej. \$2.000.000',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.attach_money),
                    ),

                    const SizedBox(height: 24),

                    /// Fecha límite.
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

                    /// Aporte inicial.
                    CustomTextField(
                      controller: _initialAmountController,
                      label: 'Aporte inicial (opcional)',
                      hintText: 'Ej. \$300.000',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.savings_outlined),
                    ),

                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Crear meta',
                      icon: Icons.flag,
                      onPressed: () {
                        // En el siguiente paso implementaremos
                        // la lógica para guardar la meta.
                      },
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
    _initialAmountController.dispose();
    super.dispose();
  }
}

/// Chip utilizado para representar una categoría de meta.
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
