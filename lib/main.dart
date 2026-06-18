import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// Flutter
import 'package:flutter/material.dart';

// Provider
import 'package:provider/provider.dart';

// Provider de autenticación
import 'providers/auth_provider.dart';
import 'providers/income_provider.dart';

// Pantalla de inicio de sesión
import 'features/auth/screens/login_screen.dart';
//import 'features/income/screens/incomes_screen.dart';

import 'shared/themes/app_theme.dart';

void main() {
  // Configuración necesaria para Windows
  if (Platform.isWindows) {
    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;
  }

  // Ejecutar la aplicación con los proveedores
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => IncomeProvider()),
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
