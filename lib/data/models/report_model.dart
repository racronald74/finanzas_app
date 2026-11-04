/// Modelo que representa los resultados financieros de un período.
class ReportModel {
  /// Fecha inicial del período consultado.
  final DateTime fechaInicio;

  /// Fecha final del período consultado.
  final DateTime fechaFin;

  /// Ingreso fijo correspondiente al período.
  final double ingresoFijo;

  /// Total de ingresos adicionales registrados.
  final double ingresosAdicionales;

  /// Total de ingresos del período.
  final double totalIngresos;

  /// Total de gastos del período.
  final double totalGastos;

  /// Saldo disponible del período.
  final double saldo;

  /// Gastos agrupados por categoría.
  final List<ReportCategoryModel> gastosPorCategoria;

  const ReportModel({
    required this.fechaInicio,
    required this.fechaFin,
    required this.ingresoFijo,
    required this.ingresosAdicionales,
    required this.totalIngresos,
    required this.totalGastos,
    required this.saldo,
    required this.gastosPorCategoria,
  });
}

/// Modelo que representa el total de gastos de una categoría.
class ReportCategoryModel {
  /// Nombre de la categoría.
  final String nombreCategoria;

  /// Monto total gastado en la categoría.
  final double totalGastos;

  const ReportCategoryModel({
    required this.nombreCategoria,
    required this.totalGastos,
  });
}
