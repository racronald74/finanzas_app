import 'package:flutter/material.dart';

import '../../../data/models/goal_model.dart';
import '../../../shared/helpers/currency_formatter.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

import 'package:provider/provider.dart';

import '../../../data/models/contribution_model.dart';
import '../../../providers/contribution_provider.dart';

/// Pantalla para registrar un nuevo aporte a una meta.
///
/// En esta primera versión se implementa la estructura visual
/// y los campos del formulario. La lógica para guardar el aporte
/// se conectará posteriormente con ContributionProvider.
class AddContributionScreen extends StatefulWidget {
  const AddContributionScreen({super.key, required this.goal});

  /// Meta a la que pertenece el aporte.
  final GoalModel goal;

  @override
  State<AddContributionScreen> createState() => _AddContributionScreenState();
}

class _AddContributionScreenState extends State<AddContributionScreen> {
  /// Controlador del monto del aporte.
  final TextEditingController _amountController = TextEditingController();

  /// Controlador de la fecha del aporte.
  final TextEditingController _dateController = TextEditingController();

  /// Controlador de la descripción opcional.
  final TextEditingController _descriptionController = TextEditingController();

  /// Método de aporte seleccionado.
  String _selectedMethod = 'Efectivo';

  /// Métodos disponibles para registrar el aporte.
  final List<String> _methods = [
    'Efectivo',
    'Transferencia',
    'Nequi',
    'Daviplata',
    'Cuenta bancaria',
  ];

  @override
  void initState() {
    super.initState();

    // Inicializa la fecha con el día actual.
    final DateTime today = DateTime.now();

    _dateController.text = _formatDate(today);
  }

  /// Abre el selector de fecha.
  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    _dateController.text = _formatDate(selectedDate);

    // Actualiza la interfaz para reflejar la nueva fecha.
    setState(() {});
  }

  /// Convierte una fecha al formato utilizado en la interfaz.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Obtiene el monto ingresado en el formulario.
  double get _enteredAmount {
    final String value = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    return double.tryParse(value) ?? 0;
  }

  /// Calcula el nuevo monto acumulado después del aporte.
  double get _newAccumulatedAmount {
    return widget.goal.montoAcumulado + _enteredAmount;
  }

  /// Calcula el nuevo progreso de la meta.
  double get _newProgress {
    if (widget.goal.montoObjetivo <= 0) {
      return 0;
    }

    return (_newAccumulatedAmount / widget.goal.montoObjetivo).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            /// Encabezado de la pantalla.
            const AppHeader(title: 'Registrar aporte', showBackButton: true),

            /// Contenido principal.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================
                    // Información de la meta
                    // ============================================
                    _GoalInformationCard(goal: widget.goal),

                    const SizedBox(height: 24),

                    // ============================================
                    // Monto del aporte
                    // ============================================
                    const Text(
                      'Monto del aporte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    CustomTextField(
                      controller: _amountController,
                      label: 'Monto del aporte',
                      hintText: 'Ej. \$300.000',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.attach_money),
                    ),

                    const SizedBox(height: 24),

                    // ============================================
                    // Método del aporte
                    // ============================================
                    const Text(
                      'Método del aporte',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _methods.map((method) {
                        return ChoiceChip(
                          label: Text(method),
                          selected: _selectedMethod == method,
                          onSelected: (_) {
                            setState(() {
                              _selectedMethod = method;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ============================================
                    // Fecha
                    // ============================================
                    CustomTextField(
                      controller: _dateController,
                      label: 'Fecha del aporte',
                      hintText: 'Seleccione una fecha',
                      readOnly: true,
                      onTap: _selectDate,
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),

                    const SizedBox(height: 24),

                    // ============================================
                    // Descripción
                    // ============================================
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Descripción (opcional)',
                      hintText: 'Ej. Ahorro de este mes',
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),

                    const SizedBox(height: 28),

                    // ============================================
                    // Impacto del aporte
                    // ============================================
                    _ContributionImpactCard(
                      currentAmount: widget.goal.montoAcumulado,
                      contributionAmount: _enteredAmount,
                      newAmount: _newAccumulatedAmount,
                      progress: _newProgress,
                      targetAmount: widget.goal.montoObjetivo,
                    ),

                    const SizedBox(height: 28),

                    // ============================================
                    // Botón registrar aporte
                    // ============================================
                    CustomButton(
                      text: 'Registrar aporte',
                      icon: Icons.savings_outlined,
                      onPressed: _saveContribution,
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
    _amountController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  /// Registra el aporte utilizando ContributionProvider.
  ///
  /// Valida el monto, convierte la fecha del formulario
  /// y crea el modelo que será almacenado en SQLite.
  Future<void> _saveContribution() async {
    // Obtiene el monto escrito por el usuario.
    final double amount = _enteredAmount;

    // El monto del aporte debe ser mayor que cero.
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto de aporte válido.')),
      );

      return;
    }

    // Convierte la fecha visual del formulario al formato
    // utilizado por los datos de la aplicación.
    final DateTime? selectedDate = _parseDate(_dateController.text);

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha válida.')),
      );

      return;
    }

    // Construye el modelo del aporte.
    final ContributionModel contribution = ContributionModel(
      monto: amount,
      fecha: _formatDatabaseDate(selectedDate),
      origen: _selectedMethod,
      idMeta: widget.goal.idMeta!,
    );

    // Obtiene el Provider encargado de registrar el aporte.
    final contributionProvider = context.read<ContributionProvider>();

    // Guarda el aporte en SQLite.
    final bool success = await contributionProvider.createContribution(
      contribution,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aporte registrado correctamente.')),
      );

      // Regresa al detalle de la meta.
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            contributionProvider.errorMessage ??
                'No se pudo registrar el aporte.',
          ),
        ),
      );
    }
  }

  /// Convierte una fecha del formulario DD/MM/YYYY
  /// a un objeto DateTime.
  DateTime? _parseDate(String value) {
    final List<String> parts = value.split('/');

    if (parts.length != 3) {
      return null;
    }

    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  /// Convierte una fecha al formato YYYY-MM-DD utilizado
  /// para almacenar información de fecha.
  String _formatDatabaseDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

/// Tarjeta que muestra la información básica de la meta.
class _GoalInformationCard extends StatelessWidget {
  const _GoalInformationCard({required this.goal});

  final GoalModel goal;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.nombre,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.savings_outlined, color: AppColors.primary),

                const SizedBox(width: 8),

                Text(
                  '${CurrencyFormatter.format(goal.montoAcumulado)}'
                  ' / '
                  '${CurrencyFormatter.format(goal.montoObjetivo)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta que muestra el impacto que tendría el aporte.
class _ContributionImpactCard extends StatelessWidget {
  const _ContributionImpactCard({
    required this.currentAmount,
    required this.contributionAmount,
    required this.newAmount,
    required this.progress,
    required this.targetAmount,
  });

  final double currentAmount;
  final double contributionAmount;
  final double newAmount;
  final double progress;
  final double targetAmount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Impacto del aporte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            _ImpactRow(
              label: 'Actual',
              value: CurrencyFormatter.format(currentAmount),
            ),

            const SizedBox(height: 10),

            _ImpactRow(
              label: 'Aporte',
              value: CurrencyFormatter.format(contributionAmount),
              valueColor: AppColors.success,
            ),

            const Divider(height: 24),

            _ImpactRow(
              label: 'Nuevo acumulado',
              value: CurrencyFormatter.format(newAmount),
              valueColor: AppColors.primary,
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nuevo progreso',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Objetivo: ${CurrencyFormatter.format(targetAmount)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila reutilizable para mostrar un valor del impacto.
class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),

        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
