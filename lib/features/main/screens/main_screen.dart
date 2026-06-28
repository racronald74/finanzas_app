import 'package:flutter/material.dart';

import '../../dashboard/screens/dashboard_screen.dart';
import '../../expense/screens/expenses_screen.dart';
import '../../income/screens/incomes_screen.dart';
import 'more_screen.dart';
import '../../../shared/widgets/app_drawer.dart';

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
    // Lo implementaremos en el siguiente paso.
  }

  Future<void> _refreshDashboard() async {
    // Lo implementaremos más adelante.
  }

  int _selectedIndex = 0;

  /// Pantallas mostradas por el BottomNavigationBar.
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      DashboardScreen(onAvatarPressed: _openDrawer),
      const IncomesScreen(),
      const ExpensesScreen(),
      const Scaffold(body: Center(child: Text('Metas'))),
      const MoreScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      drawer: const AppDrawer(),
      body: IndexedStack(index: _selectedIndex, children: _screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;
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
}
