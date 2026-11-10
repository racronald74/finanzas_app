import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/expense_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/budget_provider.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_summary.dart';
import 'add_expense_screen.dart';
import '../../../data/models/expense_model.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/app_background.dart';

/// Pantalla principal del módulo de gastos.
///
/// Permite visualizar el total gastado, consultar el presupuesto,
/// filtrar gastos, consultar el historial y registrar nuevos gastos.
class ExpensesScreen extends StatefulWidget {
  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  /// Acción ejecutada al pulsar la campana.
  final VoidCallback? onNotificationPressed;

  const ExpensesScreen({
    super.key,
    this.onAvatarPressed,
    this.onNotificationPressed,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  /// Filtro seleccionado actualmente.
  String _filtroSeleccionado = 'Todos';

  /// Detecta si está activo el tema de alto contraste.
  bool _isHighContrast(BuildContext context) {
    return Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);
  }

  /// Construye un botón de filtro.
  Widget _buildFiltro(BuildContext context, String texto) {
    final bool highContrast = _isHighContrast(context);
    final bool seleccionado = _filtroSeleccionado == texto;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _filtroSeleccionado = texto;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: seleccionado
              ? (highContrast
                    ? const Color(0xFF003B8E)
                    : const Color(0xFFD9E4FF))
              : Colors.white,
          foregroundColor: seleccionado
              ? (highContrast ? Colors.white : const Color(0xFF4A4A4A))
              : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 10),
          side: BorderSide(
            color: highContrast
                ? Colors.black
                : (seleccionado
                      ? const Color(0xFFD9E4FF)
                      : const Color(0xFFD0D0D0)),
            width: highContrast ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (seleccionado) ...[
              const Icon(Icons.check, size: 18),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final usuario = authProvider.currentUser;

      if (usuario == null) return;

      final incomeProvider = Provider.of<IncomeProvider>(
        context,
        listen: false,
      );

      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );

      await incomeProvider.loadIncomeData(usuario.idUsuario!);

      await expenseProvider.loadExpenses(usuario.idUsuario!);
      if (!mounted) return;

      _updateBudget();
    });
  }

  /// Actualiza el resumen del presupuesto para el período actual.
  Future<void> _updateBudget() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    final usuario = authProvider.currentUser;

    if (usuario == null) return;

    final now = DateTime.now();

    final currentPeriodStart = DateTime(now.year, now.month, 1);

    final initialBalance = await budgetProvider.calculateInitialBalance(
      idUsuario: usuario.idUsuario!,
      currentPeriodStart: currentPeriodStart,
      fixedIncome: usuario.ingresoFijoMensual,
      registrationDate: DateTime.parse(usuario.fechaRegistro),
    );

    if (!mounted) return;

    budgetProvider.updateBudget(
      initialBalance: initialBalance,
      fixedIncome: usuario.ingresoFijoMensual,
      additionalIncome: incomeProvider.currentMonthAdditionalIncome,
      totalExpenses: expenseProvider.totalExpenses,
      totalSavings: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool highContrast = _isHighContrast(context);

    // Obtiene el proveedor del módulo de gastos.
    final expenseProvider = Provider.of<ExpenseProvider>(context);

    final budgetProvider = Provider.of<BudgetProvider>(context);

    // Lista que se mostrará en pantalla.
    List<ExpenseModel> gastosFiltrados = expenseProvider.expenses;

    // Fecha actual.
    final ahora = DateTime.now();

    switch (_filtroSeleccionado) {
      case 'Hoy':
        gastosFiltrados = expenseProvider.expenses.where((gasto) {
          final fecha = DateTime.parse(gasto.fecha);

          return fecha.year == ahora.year &&
              fecha.month == ahora.month &&
              fecha.day == ahora.day;
        }).toList();
        break;

      case 'Semana':
        gastosFiltrados = expenseProvider.expenses.where((gasto) {
          final fecha = DateTime.parse(gasto.fecha);

          return ahora.difference(fecha).inDays <= 7;
        }).toList();
        break;

      case 'Mes':
        gastosFiltrados = expenseProvider.expenses.where((gasto) {
          final fecha = DateTime.parse(gasto.fecha);

          return fecha.year == ahora.year && fecha.month == ahora.month;
        }).toList();
        break;

      default:
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: AppBackground(
        child: Column(
          children: [
            // Encabezado reutilizable de la aplicación.
            AppHeader(
              title: 'Gastos',
              showAvatar: true,
              showNotification: true,
              onAvatarPressed: widget.onAvatarPressed,
              onNotificationPressed: widget.onNotificationPressed,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpenseSummary(
                      totalGastado: budgetProvider.summary.totalExpenses,
                      disponible: budgetProvider.summary.availableBudget,
                      usedPercentage: budgetProvider.summary.usedPercentage,
                      availablePercentage:
                          budgetProvider.summary.availablePercentage,
                      totalIncome:
                          budgetProvider.summary.initialBalance +
                          budgetProvider.summary.totalIncome,
                    ),

                    const SizedBox(height: 10),

                    // Filtros de gastos.
                    Row(
                      children: [
                        Expanded(child: _buildFiltro(context, 'Todos')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildFiltro(context, 'Hoy')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildFiltro(context, 'Semana')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildFiltro(context, 'Mes')),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Lista de gastos',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: highContrast ? Colors.black : null,
                      ),
                    ),

                    // Historial de gastos.
                    Expanded(
                      child: gastosFiltrados.isEmpty
                          ? SizedBox(
                              width: double.infinity,
                              child: Card(
                                color: Colors.white,
                                elevation: highContrast ? 0 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: highContrast
                                      ? const BorderSide(
                                          color: Colors.black,
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        size: 60,
                                        color: highContrast
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay gastos registrados',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: highContrast
                                              ? Colors.black
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Registra tu primer gasto para comenzar a controlar tus finanzas.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: highContrast
                                              ? Colors.black
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              // Mantiene un espacio entre el título
                              // y la primera tarjeta.
                              padding: const EdgeInsets.only(top: 10),
                              itemCount: gastosFiltrados.length,
                              itemBuilder: (context, index) {
                                final gasto = gastosFiltrados[index];

                                // Construye una tarjeta personalizada.
                                return ExpenseCard(
                                  expense: gasto,
                                  onEdit: () async {
                                    final authProvider =
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );

                                    final expenseProvider =
                                        Provider.of<ExpenseProvider>(
                                          context,
                                          listen: false,
                                        );

                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AddExpenseScreen(expense: gasto),
                                      ),
                                    );

                                    if (!mounted) return;

                                    final usuario = authProvider.currentUser;

                                    if (usuario != null) {
                                      await expenseProvider.loadExpenses(
                                        usuario.idUsuario!,
                                      );

                                      _updateBudget();
                                    }
                                  },
                                  onDelete: () async {
                                    final authProvider =
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );

                                    final expenseProvider =
                                        Provider.of<ExpenseProvider>(
                                          context,
                                          listen: false,
                                        );

                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );

                                    final usuario = authProvider.currentUser;

                                    if (usuario == null) return;

                                    // Solicita confirmación antes de eliminar.
                                    final confirmar = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) {
                                        return AlertDialog(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            side: highContrast
                                                ? const BorderSide(
                                                    color: Colors.black,
                                                    width: 2,
                                                  )
                                                : BorderSide.none,
                                          ),
                                          title: Text(
                                            'Eliminar gasto',
                                            style: TextStyle(
                                              color: highContrast
                                                  ? Colors.black
                                                  : null,
                                            ),
                                          ),
                                          content: Text(
                                            '¿Está seguro de eliminar este gasto?',
                                            style: TextStyle(
                                              color: highContrast
                                                  ? Colors.black
                                                  : null,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  dialogContext,
                                                  false,
                                                );
                                              },
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: highContrast
                                                    ? const Color(0xFF003B8E)
                                                    : null,
                                                foregroundColor: highContrast
                                                    ? Colors.white
                                                    : null,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(
                                                  dialogContext,
                                                  true,
                                                );
                                              },
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirmar != true) return;

                                    // Elimina el gasto.
                                    await expenseProvider.deleteExpense(
                                      gasto.idGasto!,
                                      usuario.idUsuario!,
                                    );

                                    if (!mounted) return;

                                    _updateBudget();

                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Gasto eliminado correctamente',
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );

                          final expenseProvider = Provider.of<ExpenseProvider>(
                            context,
                            listen: false,
                          );

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddExpenseScreen(),
                            ),
                          );

                          if (!mounted) return;

                          final usuario = authProvider.currentUser;

                          if (usuario != null) {
                            await expenseProvider.loadExpenses(
                              usuario.idUsuario!,
                            );

                            _updateBudget();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Registrar nuevo gasto',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: highContrast
                              ? const Color(0xFF003B8E)
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: highContrast ? 0 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: highContrast
                                ? const BorderSide(
                                    color: Colors.black,
                                    width: 1,
                                  )
                                : BorderSide.none,
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
      ),
    );
  }
}
