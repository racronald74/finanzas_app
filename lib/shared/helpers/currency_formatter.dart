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
  /// Ejemplo:
  /// 1300000 -> $1.300.000
  static String format(num value) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    );

    return formatter.format(value);
  }
}
