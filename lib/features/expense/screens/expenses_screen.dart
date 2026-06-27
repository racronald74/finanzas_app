// Librería principal de Flutter
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

/// Pantalla principal del módulo de gastos.
///
/// Permite:
/// - Visualizar el total gastado.
/// - Consultar el presupuesto disponible.
/// - Filtrar gastos.
/// - Consultar el historial.
/// - Registrar nuevos gastos.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  /// Filtro seleccionado actualmente.
  ///
  /// Valores posibles:
  /// - Todos
  /// - Hoy
  /// - Semana
  /// - Mes
  String _filtroSeleccionado = 'Todos';

  /// Construye un botón de filtro.
  ///
  /// El botón cambia de color cuando está seleccionado.
  Widget _buildFiltro(String texto) {
    final bool seleccionado = _filtroSeleccionado == texto;

    return ChoiceChip(
      label: Text(texto),

      selected: seleccionado,

      onSelected: (_) {
        setState(() {
          _filtroSeleccionado = texto;
        });
      },
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

  void _updateBudget() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    budgetProvider.updateBudget(
      fixedIncome: authProvider.currentUser?.ingresoFijoMensual ?? 0,
      additionalIncome: incomeProvider.totalIncome,
      totalExpenses: expenseProvider.totalExpenses,
      totalSavings: 0,
    );
  }

  @override
  // Construcción de la interfaz de usuario
  Widget build(BuildContext context) {
    // Obtiene el proveedor del módulo de gastos.
    // Permite acceder a la lista y al total gastado.
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
      // Barra superior
      appBar: AppBar(title: const Text('Gastos')),

      // Contenido principal
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Contenido de la pantalla
          children: [
            ExpenseSummary(
              totalGastado: budgetProvider.summary.totalExpenses,
              disponible: budgetProvider.summary.availableBudget,
              usedPercentage: budgetProvider.summary.usedPercentage,
              availablePercentage: budgetProvider.summary.availablePercentage,
              totalIncome: budgetProvider.summary.totalIncome,
            ),

            const SizedBox(height: 16),

            /// Filtros
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: Row(
                children: [
                  _buildFiltro('Todos'),

                  const SizedBox(width: 8),

                  _buildFiltro('Hoy'),

                  const SizedBox(width: 8),

                  _buildFiltro('Semana'),

                  const SizedBox(width: 8),

                  _buildFiltro('Mes'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// Historial de gastos
            gastosFiltrados.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      // Mensaje cuando no hay gastos registrados
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 60,
                            color: Colors.grey,
                          ),

                          const SizedBox(height: 16),
                          // Mensaje cuando no hay gastos registrados
                          const Text(
                            'No hay gastos registrados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),
                          // Mensaje adicional para motivar al usuario a registrar su primer gasto
                          const Text(
                            'Registra tu primer gasto para comenzar a controlar tus finanzas.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                /// Lista de gastos registrados
                : ListView.builder(
                    shrinkWrap: true,

                    physics: const NeverScrollableScrollPhysics(),
                    // Construye la lista de gastos filtrados
                    itemCount: gastosFiltrados.length,
                    //
                    itemBuilder: (context, index) {
                      final gasto = gastosFiltrados[index];
                      // Construye una tarjeta personalizada.
                      return ExpenseCard(
                        expense: gasto,
                        onEdit: () async {
                          // Abre la pantalla en modo edición.
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddExpenseScreen(expense: gasto),
                            ),
                          );

                          // Si la pantalla ya no existe, termina el método.
                          if (!mounted) return;

                          // Recarga la lista de gastos.
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );

                          final usuario = authProvider.currentUser;

                          if (usuario != null) {
                            await Provider.of<ExpenseProvider>(
                              context,
                              listen: false,
                            ).loadExpenses(usuario.idUsuario!);

                            _updateBudget();
                          }
                        },
                        // Acción para eliminar el gasto.
                        onDelete: () async {
                          final confirmar = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Eliminar gasto'),
                                content: const Text(
                                  '¿Está seguro de eliminar este gasto?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmar != true) return;

                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );

                          final usuario = authProvider.currentUser;

                          if (usuario == null) return;

                          await Provider.of<ExpenseProvider>(
                            context,
                            listen: false,
                          ).deleteExpense(gasto.idGasto!, usuario.idUsuario!);

                          _updateBudget();

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gasto eliminado correctamente'),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),

      /// Botón flotante
      floatingActionButton: FloatingActionButton(
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
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );

          final usuario = authProvider.currentUser;

          if (usuario != null) {
            await expenseProvider.loadExpenses(usuario.idUsuario!);

            _updateBudget();
          }
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}
