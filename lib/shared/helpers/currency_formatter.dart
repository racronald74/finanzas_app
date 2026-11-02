import 'package:intl/intl.dart';

/// Clase utilitaria para dar formato a valores monetarios.
///
/// Centraliza el formato utilizado en toda la aplicación para
/// evitar repetir lógica en los diferentes módulos.
class CurrencyFormatter {
  /// Constructor privado para impedir instancias.
  CurrencyFormatter._();

  /// Devuelve un valor con formato de moneda colombiana.
  ///
  /// Siempre muestra dos decimales.
  /// Ejemplo: 3259.3 -> $3.259,30
  static String format(num value) {
    // Configura separadores de miles y decimales para Colombia.
    final NumberFormat formatter = NumberFormat('#,##0.00', 'es_CO');

    // Agrega el símbolo de pesos al valor formateado.
    return '\$${formatter.format(value)}';
  }
}
