import 'package:flutter/material.dart';

import '../../dashboard/screens/dashboard_screen.dart';
import '../../expense/screens/expenses_screen.dart';
import '../../income/screens/incomes_screen.dart';
import 'more_screen.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../goal/screens/goals_screen.dart';
import '../../obligaciones/screens/obligations_screen.dart';

import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/budget_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// Información de cada pestaña del BottomNavigationBar.
///
/// Permite definir el título, tipo de encabezado y comportamiento
/// de cada módulo desde un único lugar.
class MainTab {
  final Widget screen;
  final String title;
  final bool isDashboard;
  final bool showFab;

  const MainTab({
    required this.screen,
    required this.title,
    this.isDashboard = false,
    this.showFab = false,
  });
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Abre el Drawer principal de la aplicación.
  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _refreshIncomes() async {
    // Lo implementaremos en el siguiente paso.
  }

  Future<void> _refreshExpenses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final usuario = authProvider.currentUser;

    if (usuario == null) return;

    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);

    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );

    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    await incomeProvider.loadIncomeData(usuario.idUsuario!);
    await expenseProvider.loadExpenses(usuario.idUsuario!);

    budgetProvider.updateBudget(
      fixedIncome: authProvider.currentUser?.ingresoFijoMensual ?? 0,
      additionalIncome: incomeProvider.currentMonthAdditionalIncome,
      totalExpenses: expenseProvider.totalExpenses,
      totalSavings: 0,
    );
  }

  Future<void> _refreshDashboard() async {
    // Lo implementaremos más adelante.
  }

  int _selectedIndex = 0;

  /// Indica si dentro de la sección Más
  /// se está mostrando Obligaciones.
  bool _showObligations = false;

  /// Información de cada pestaña de la aplicación.
  late final List<MainTab> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = [
      MainTab(
        screen: DashboardScreen(onAvatarPressed: _openDrawer),
        title: 'Dashboard',
        isDashboard: true,
      ),

      MainTab(
        screen: IncomesScreen(
          // Utiliza el mismo Drawer que Gastos y Metas.
          onAvatarPressed: _openDrawer,
        ),
        title: 'Ingresos',
      ),

      MainTab(
        screen: ExpensesScreen(
          // Utiliza el mismo Drawer que abre el avatar de Metas.
          onAvatarPressed: _openDrawer,
        ),
        title: 'Gastos',
      ),

      MainTab(
        screen: GoalsScreen(
          // Utiliza el mismo Drawer que abre el avatar del Dashboard.
          onAvatarPressed: _openDrawer,
        ),
        title: 'Metas',
      ),

      MainTab(
        screen: MoreScreen(onObligationsPressed: _openObligations),
        title: 'Más',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ..._tabs.take(4).map((tab) => tab.screen),

          _showObligations
              ? ObligationsScreen()
              : MoreScreen(onObligationsPressed: _openObligations),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;

            // Al volver a Más, mostrar nuevamente MoreScreen.
            if (index == 4) {
              _showObligations = false;
            }
          });

          switch (index) {
            case 0:
              _refreshDashboard();
              break;

            case 1:
              _refreshIncomes();
              break;

            case 2:
              _refreshExpenses();
              break;
          }
        },

        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Ingreso',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Gasto',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.savings_outlined),
            label: 'Meta',
          ),

          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Más'),
        ],
      ),
    );
  }

  /// Abre la pantalla de Obligaciones dentro
  /// de la sección Más.
  ///
  /// No cambia la pestaña principal, por lo que
  /// el BottomNavigationBar continúa mostrando Más.
  void _openObligations() {
    setState(() {
      _showObligations = true;
    });
  }
}
