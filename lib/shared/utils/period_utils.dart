/// Utilidad para trabajar con períodos mensuales.
class PeriodUtils {
  /// Devuelve el primer día del mes indicado.
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Devuelve el primer día del mes siguiente.
  static DateTime startOfNextMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 1);
  }

  /// Devuelve el primer día del mes anterior.
  static DateTime startOfPreviousMonth(DateTime date) {
    return DateTime(date.year, date.month - 1, 1);
  }

  /// Convierte una fecha a formato ISO conservando únicamente la fecha.
  static String toDateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
