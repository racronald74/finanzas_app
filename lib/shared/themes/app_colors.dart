import 'package:flutter/material.dart';

/// Paleta oficial de colores de FinanzApp.
///
/// Centraliza todos los colores utilizados en la aplicación.
/// De esta forma evitamos escribir colores directamente
/// (Colors.blue, Colors.red, etc.) en los widgets.
class AppColors {
  AppColors._();

  // ===============================
  // Colores principales
  // ===============================

  /// Azul principal de la aplicación.
  static const Color primary = Color(0xFF3F6DB5);

  /// Fondo general de la aplicación.
  static const Color background = Color(0xFFF8F9FC);

  /// Fondo de tarjetas.
  static const Color cardBackground = Color(0xFFFDFDFF);

  // ===============================
  // Colores de texto
  // ===============================

  /// Texto principal.
  static const Color textPrimary = Color(0xFF222222);

  /// Texto secundario.
  static const Color textSecondary = Color(0xFF8A8A8A);

  /// Texto blanco.
  static const Color textLight = Colors.white;

  // ===============================
  // Colores de estados
  // ===============================

  /// Estado informativo.
  static const Color info = Color(0xFF3F6DB5);

  /// Estado exitoso.
  static const Color success = Color(0xFF22B35E);

  /// Estado de advertencia.
  static const Color warning = Color(0xFFFFB52E);

  /// Estado de error.
  static const Color danger = Color(0xFFE53935);

  /// Estado neutro.
  static const Color neutral = Color(0xFFBDBDBD);

  // ===============================
  // Colores de progreso
  // ===============================

  /// Barra de progreso.
  static const Color progress = Color(0xFF2365D1);

  /// Fondo de la barra de progreso.
  static const Color progressBackground = Color(0xFFDCE7FA);

  // ===============================
  // Colores de bordes
  // ===============================

  /// Borde claro.
  static const Color border = Color(0xFFE3E6EB);

  // ===============================
  // Colores de iconos
  // ===============================

  /// Fondo circular de iconos.
  static const Color iconBackground = Color(0xFFE8F0FF);

  /// Color principal de iconos.
  static const Color icon = primary;
}
