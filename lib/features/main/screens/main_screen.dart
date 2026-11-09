import 'package:flutter/material.dart';

import '../../dashboard/screens/dashboard_screen.dart';
import '../../expense/screens/expenses_screen.dart';
import '../../income/screens/incomes_screen.dart';
import 'more_screen.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../goal/screens/goals_screen.dart';
import '../../obligaciones/screens/obligations_screen.dart';
import '../../debt/screens/debts_screen.dart';

import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../reportes/screens/reports_screen.dart';
import '../../notificaciones/screens/notifications_screen.dart';
import '../../notificaciones/screens/notification_settings_screen.dart';

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

  /// Actualiza el resumen del presupuesto para el período actual.
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

  Future<void> _refreshDashboard() async {
    // Lo implementaremos más adelante.
  }

  int _selectedIndex = 0;

  /// Indica si dentro de la sección Más
  /// se está mostrando Obligaciones.
  bool _showObligations = false;

  /// Permite reconstruir ObligationsScreen cada vez
  /// que se vuelve a abrir.
  Key _obligationsKey = UniqueKey();

  /// Indica si dentro de la sección Más
  /// se está mostrando Deudas.
  bool _showDebts = false;

  /// Indica si se está mostrando la pantalla de Reportes.
  bool _showReports = false;

  /// Indica si se está mostrando la pantalla de Notificaciones.
  bool _showNotifications = false;

  /// Guarda la sección desde la que se abrió Notificaciones.
  int? _previousIndex;

  /// Guarda si Notificaciones se abrió desde otra pantalla de Más.
  String? _previousMoreScreen;

  /// Indica si se está mostrando la configuración de notificaciones.
  bool _showNotificationSettings = false;

  /// Permite reconstruir DebtsScreen cada vez
  /// que se vuelve a abrir.
  Key _debtsKey = UniqueKey();

  /// Información de cada pestaña de la aplicación.
  late final List<MainTab> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = [
      MainTab(
        screen: DashboardScreen(
          onAvatarPressed: _openDrawer,
          onNotificationPressed: _openNotifications,
        ),
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
          onNotificationPressed: _openNotifications,
        ),
        title: 'Gastos',
      ),

      MainTab(
        screen: GoalsScreen(
          // Utiliza el mismo Drawer que abre el avatar del Dashboard.
          onAvatarPressed: _openDrawer,
          onNotificationPressed: _openNotifications,
        ),
        title: 'Metas',
      ),

      MainTab(
        screen: MoreScreen(
          onObligationsPressed: _openObligations,
          onDebtsPressed: _openDebts,
          onReportsPressed: _openReports,
          onNotificationsPressed: _openNotifications,
          onAvatarPressed: _openDrawer,
        ),
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
              ? ObligationsScreen(
                  key: _obligationsKey,
                  onAvatarPressed: _openDrawer,
                  onNotificationPressed: _openNotifications,
                )
              : _showDebts
              ? DebtsScreen(
                  key: _debtsKey,
                  onAvatarPressed: _openDrawer,
                  onNotificationPressed: _openNotifications,
                )
              : _showReports
              ? ReportsScreen(
                  onAvatarPressed: _openDrawer,
                  onNotificationPressed: _openNotifications,
                )
              : _showNotificationSettings
              ? NotificationSettingsScreen(
                  onBackPressed: _backToNotifications,
                  onAvatarPressed: _openDrawer,
                )
              : _showNotifications
              ? NotificationsScreen(
                  onAvatarPressed: _openDrawer,
                  onSettingsPressed: _openNotificationSettings,
                  onBackPressed: _backFromNotifications,
                )
              : MoreScreen(
                  onObligationsPressed: _openObligations,
                  onDebtsPressed: _openDebts,
                  onReportsPressed: _openReports,
                  onNotificationsPressed: _openNotifications,
                  onAvatarPressed: _openDrawer,
                ),
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
              _showDebts = false;
              _showReports = false;
              _showNotifications = false;
              _showNotificationSettings = false;
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

  /// Abre Obligaciones y fuerza una nueva carga de datos.
  void _openObligations() {
    setState(() {
      _obligationsKey = UniqueKey();
      _showObligations = true;
      _showDebts = false;
      _showReports = false;
    });
  }

  /// Abre Deudas y fuerza una nueva carga de datos.
  void _openDebts() {
    setState(() {
      _debtsKey = UniqueKey();
      _showDebts = true;
      _showObligations = false;
      _showReports = false;
    });
  }

  /// Abre la pantalla de Reportes.
  void _openReports() {
    setState(() {
      _showObligations = false;
      _showDebts = false;
      _showReports = true;
    });
  }

  /// Abre Notificaciones y guarda la pantalla de origen.
  void _openNotifications() {
    setState(() {
      // Guarda la pestaña principal desde la que se abrió.
      _previousIndex = _selectedIndex;

      // Identifica si se abrió desde alguna pantalla de Más.
      if (_showObligations) {
        _previousMoreScreen = 'obligations';
      } else if (_showDebts) {
        _previousMoreScreen = 'debts';
      } else if (_showReports) {
        _previousMoreScreen = 'reports';
      } else {
        _previousMoreScreen = null;
      }

      _selectedIndex = 4;

      // Muestra Notificaciones.
      _showObligations = false;
      _showDebts = false;
      _showReports = false;
      _showNotificationSettings = false;
      _showNotifications = true;
    });
  }

  /// Abre la configuración de notificaciones.
  void _openNotificationSettings() {
    setState(() {
      _showObligations = false;
      _showDebts = false;
      _showReports = false;
      _showNotifications = false;
      _showNotificationSettings = true;
    });
  }

  /// Regresa a la pantalla desde la que se abrieron las notificaciones.
  void _backFromNotifications() {
    setState(() {
      _showNotifications = false;

      // Si se abrió desde otra pantalla de la sección Más,
      // restaura esa pantalla.
      _showObligations = _previousMoreScreen == 'obligations';
      _showDebts = _previousMoreScreen == 'debts';
      _showReports = _previousMoreScreen == 'reports';

      // Si no había una pantalla secundaria de Más,
      // restaura la pestaña principal anterior.
      if (_previousMoreScreen == null && _previousIndex != null) {
        _selectedIndex = _previousIndex!;
      }

      // Limpia el origen guardado.
      _previousIndex = null;
      _previousMoreScreen = null;
    });
  }

  /// Regresa desde la configuración al listado de notificaciones.
  void _backToNotifications() {
    setState(() {
      _showNotificationSettings = false;
      _showNotifications = true;
    });
  }
}
