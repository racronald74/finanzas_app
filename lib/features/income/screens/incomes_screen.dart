import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/income_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/income_provider.dart';
import 'add_income_screen.dart';

import '../../../providers/expense_provider.dart';
import '../../../providers/budget_provider.dart';
import '../widgets/income_header.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../data/repositories/fixed_income_history_repository.dart';

// Pantalla que muestra los ingresos del usuario y permite agregar, editar o eliminar ingresos adicionales.
class IncomesScreen extends StatefulWidget {
  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  const IncomesScreen({super.key, this.onAvatarPressed});

  @override
  State<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends State<IncomesScreen> {
  /// Formatea valores monetarios con separador de miles
  /// y coloca el símbolo de moneda antes del valor.
  String _formatCurrency(double value) {
    final formatted = NumberFormat('#,##0', 'es_CO').format(value);

    return '\$$formatted';
  }

  /// Mes y año actualmente seleccionados.
  DateTime _selectedPeriod = DateTime.now();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIncomeData();
    });
  }

  /// Obtiene el texto correspondiente al período actual.
  String _getCurrentPeriodText() {
    final selected = _selectedPeriod;
    final current = DateTime.now();

    const monthNames = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    final monthName = monthNames[selected.month - 1];

    final isCurrentPeriod =
        selected.year == current.year && selected.month == current.month;

    return isCurrentPeriod
        ? 'Mes actual - $monthName ${selected.year}'
        : '$monthName ${selected.year}';
  }

  /// Abre el selector para cambiar el mes y año.
  Future<void> _selectPeriod() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedPeriod,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Seleccionar período',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (selectedDate == null) return;

    setState(() {
      _selectedPeriod = DateTime(selectedDate.year, selectedDate.month);
    });

    // Carga el ingreso fijo correspondiente al nuevo período.
    await _loadFixedIncomeForSelectedPeriod();
  }

  /// Devuelve los ingresos adicionales correspondientes
  /// al mes y año actualmente seleccionados.
  List<IncomeModel> _getFilteredIncomes(List<IncomeModel> incomes) {
    return incomes.where((income) {
      final incomeDate = DateTime.parse(income.fecha);

      return incomeDate.year == _selectedPeriod.year &&
          incomeDate.month == _selectedPeriod.month;
    }).toList();
  }

  /// Carga la información de ingresos, gastos y actualiza
  /// el presupuesto del usuario autenticado.
  Future<void> _loadIncomeData() async {
    // Obtiene el usuario autenticado.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Obtiene los providers antes de cualquier operación asíncrona.
    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    final user = authProvider.currentUser;

    if (user == null) return;

    // Carga los ingresos.
    await incomeProvider.loadIncomeData(user.idUsuario!);
    // Carga los gastos.
    await expenseProvider.loadExpenses(user.idUsuario!);

    // Verifica que la pantalla siga activa.
    if (!mounted) return;

    // Actualiza el presupuesto.
    await _refreshBudget();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);

    final filteredIncomes = _getFilteredIncomes(
      incomeProvider.additionalIncomes,
    );

    final currentDate = DateTime.now();

    final isCurrentPeriod =
        _selectedPeriod.year == currentDate.year &&
        _selectedPeriod.month == currentDate.month;

    final fixedIncome = isCurrentPeriod
        ? authProvider.currentUser?.ingresoFijoMensual ?? 0
        : _selectedPeriodFixedIncome ?? 0;

    return Scaffold(
      body: Column(
        children: [
          IncomeHeader(
            periodText: _getCurrentPeriodText(),
            onCalendarPressed: _selectPeriod,
            onAvatarPressed: widget.onAvatarPressed,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 150,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Ingreso fijo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                    ),
                                  ),

                                  Text(
                                    _formatCurrency(fixedIncome),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),

                                  TextButton(
                                    onPressed: _editFixedIncome,
                                    style: TextButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Modificar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: SizedBox(
                          height: 150,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Total disponible',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                    ),
                                  ),

                                  Text(
                                    _formatCurrency(
                                      budgetProvider.summary.availableBudget,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),

                                  const Text(
                                    'Este mes + saldos anteriores',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Mensaje informativo sobre los saldos anteriores.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.info_circle,
                          size: 20,
                          color: Color(0xFF4380E5),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'El total disponible incluye saldos anteriores.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF315B9A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Historial de ingresos adicionales.
                  const Text(
                    'Historial de ingresos adicionales',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 8),

                  // Solo el historial de ingresos tendrá desplazamiento.
                  Expanded(
                    child: incomeProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredIncomes.isEmpty
                        ? SizedBox(
                            width: double.infinity,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    // Icono representativo del estado vacío.
                                    const Icon(
                                      Icons.receipt_long,
                                      size: 60,
                                      color: Colors.grey,
                                    ),

                                    const SizedBox(height: 16),

                                    // Mensaje principal.
                                    const Text(
                                      'No hay ingresos registrados',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Explicación del estado vacío.
                                    const Text(
                                      'Registra tu primer ingreso para comenzar a controlar tus finanzas.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,

                            // Se reserva la primera posición para el ingreso fijo
                            // correspondiente al período seleccionado.
                            itemCount:
                                filteredIncomes.length +
                                (_selectedPeriodFixedIncome != null ? 1 : 0),

                            itemBuilder: (context, index) {
                              // Muestra primero el ingreso fijo histórico.
                              if (_selectedPeriodFixedIncome != null &&
                                  index == 0) {
                                return _fixedIncomeHistoryTile(
                                  _selectedPeriodFixedIncome!,
                                );
                              }

                              // Ajusta el índice porque el primer elemento
                              // corresponde al ingreso fijo.
                              final incomeIndex =
                                  _selectedPeriodFixedIncome != null
                                  ? index - 1
                                  : index;

                              return _incomeTile(filteredIncomes[incomeIndex]);
                            },
                          ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddIncomeScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await _loadIncomeData();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Registrar nuevo ingreso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4380E5),
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
          ),
        ],
      ),
    );
  }

  String _formatDate(String fecha) {
    final date = DateTime.parse(fecha);

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Construye la tarjeta del ingreso fijo correspondiente
  /// al período seleccionado.
  Widget _fixedIncomeHistoryTile(double monto) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFFC7DFDE),
              child: Icon(Iconsax.money_recive, size: 30, color: Colors.green),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingreso fijo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Ingreso fijo mensual del período',
                    style: TextStyle(color: Colors.black87),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${_selectedPeriod.month.toString().padLeft(2, '0')}/'
                    '${_selectedPeriod.year}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Text(
              _formatCurrency(monto),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _incomeTile(IncomeModel income) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Color.fromARGB(255, 199, 223, 222),
              child: Icon(Iconsax.money_recive, size: 30, color: Colors.green),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    income.fuente ?? 'Sin categoría',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    income.descripcion.trim().isEmpty
                        ? 'Sin descripción'
                        : income.descripcion,
                    style: TextStyle(
                      fontStyle: income.descripcion.trim().isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: income.descripcion.trim().isEmpty
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _formatDate(income.fecha),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatCurrency(income.monto),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Iconsax.edit, size: 28),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddIncomeScreen(initialIncome: income),
                          ),
                        );

                        if (!mounted) return;
                        await _loadIncomeData();
                      },
                    ),

                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Iconsax.trash,
                        size: 28,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmDelete(income),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editFixedIncome() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final initialValue =
        authProvider.currentUser?.ingresoFijoMensual.toString() ?? '0';

    final result = await showDialog<double>(
      context: context,
      builder: (_) => _FixedIncomeDialog(initialValue: initialValue),
    );

    if (result == null) return;
    if (!mounted) return;

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final success = await authProvider.updateFixedIncome(result);

    if (!mounted) return;

    if (success) {
      await _loadIncomeData();
    }

    _showMessage(
      success ? 'Ingreso fijo actualizado' : 'No fue posible actualizar',
    );
  }

  Future<void> _confirmDelete(IncomeModel income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar ingreso'),
          content: const Text('Esta accion no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);

    final success = await incomeProvider.deleteIncome(income);

    if (!mounted) return;

    if (success) {
      await _loadIncomeData();
    }

    _showMessage(success ? 'Ingreso eliminado' : 'No fue posible eliminar');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Actualiza el resumen del presupuesto para el período actual.
  Future<void> _refreshBudget() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    final user = authProvider.currentUser;

    if (user == null) return;

    // El presupuesto siempre corresponde al período actual.
    // El filtro del historial es independiente.
    final now = DateTime.now();

    final currentPeriodStart = DateTime(now.year, now.month, 1);

    final initialBalance = await budgetProvider.calculateInitialBalance(
      idUsuario: user.idUsuario!,
      currentPeriodStart: currentPeriodStart,
      fixedIncome: user.ingresoFijoMensual,
      registrationDate: DateTime.parse(user.fechaRegistro),
    );

    if (!mounted) return;

    budgetProvider.updateBudget(
      initialBalance: initialBalance,
      fixedIncome: user.ingresoFijoMensual,
      additionalIncome: incomeProvider.currentMonthAdditionalIncome,
      totalExpenses: expenseProvider.totalExpenses,
      totalSavings: 0,
    );
  }

  /// Repositorio encargado de consultar el histórico
  /// del ingreso fijo mensual.
  final FixedIncomeHistoryRepository _fixedIncomeHistoryRepository =
      FixedIncomeHistoryRepository();

  /// Ingreso fijo correspondiente al período seleccionado.
  double? _selectedPeriodFixedIncome;

  /// Obtiene el ingreso fijo correspondiente al período seleccionado.
  Future<void> _loadFixedIncomeForSelectedPeriod() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;

    if (user == null) return;

    final periodStart = DateTime(
      _selectedPeriod.year,
      _selectedPeriod.month,
      1,
    );

    final history = await _fixedIncomeHistoryRepository.getByPeriod(
      idUsuario: user.idUsuario!,
      periodStart: periodStart,
    );

    if (!mounted) return;

    setState(() {
      // Utiliza el histórico cuando existe.
      // Si no existe, todavía no se muestra un ingreso fijo
      // para ese período.
      _selectedPeriodFixedIncome = history?.monto;
    });
  }
}

class _FixedIncomeDialog extends StatefulWidget {
  final String initialValue;

  const _FixedIncomeDialog({required this.initialValue});

  @override
  State<_FixedIncomeDialog> createState() => _FixedIncomeDialogState();
}

class _FixedIncomeDialogState extends State<_FixedIncomeDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatAmount(widget.initialValue),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ingreso fijo mensual'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Monto',
          prefixText: r'$',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  void _save() {
    /// Convierte el monto mostrado con separadores
    /// de miles al valor numérico utilizado por la aplicación.
    final texto = _controller.text
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');

    final value = double.tryParse(texto);

    if (value == null || value < 0) {
      setState(() {
        _errorText = 'Ingrese un monto valido';
      });
      return;
    }

    Navigator.pop(context, value);
  }

  /// Formatea el monto para mostrarlo con separador de miles.
  String _formatAmount(String value) {
    final number = double.tryParse(value);

    if (number == null) {
      return value;
    }

    return NumberFormat('#,##0', 'es_CO').format(number);
  }
}
