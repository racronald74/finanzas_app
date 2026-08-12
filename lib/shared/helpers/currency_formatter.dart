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
    // Formatea únicamente la parte numérica con separador
    // de miles y sin decimales.
    final NumberFormat formatter = NumberFormat.decimalPattern('es_CO');

    // Agrega manualmente el símbolo de pesos al inicio
    // para garantizar el mismo formato en toda la aplicación.
    return '\$${formatter.format(value)}';
  }
}
