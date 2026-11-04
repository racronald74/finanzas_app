import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// Flutter
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

// Provider
import 'package:provider/provider.dart';
// Provider de autenticación
import 'providers/auth_provider.dart';
import 'providers/income_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/contribution_provider.dart';
import 'providers/obligation_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/report_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// Pantalla de inicio de sesión
import 'features/auth/screens/login_screen.dart';
//import 'features/income/screens/incomes_screen.dart';

import 'shared/themes/app_theme.dart';

/// Punto de entrada principal de la aplicación.
Future<void> main() async {
  // Inicializa Flutter antes de configurar la aplicación.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa los datos de fechas en español colombiano.
  await initializeDateFormatting('es_CO');

  // La aplicación funcionará únicamente en orientación vertical.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Configuración necesaria para Windows.
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Ejecuta la aplicación con los proveedores.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => ContributionProvider()),
        ChangeNotifierProvider(create: (_) => ObligationProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Widget principal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Finanzas App',

      theme: AppTheme.lightTheme,

      // Primera pantalla de la aplicación
      home: const LoginScreen(),
    );
  }
}
