import '../models/report_model.dart';
import '../repositories/report_repository.dart';

/// Servicio encargado de calcular los resultados financieros
/// utilizados por el módulo de reportes.
class ReportService {
  final ReportRepository _reportRepository = ReportRepository();

  /// Genera el reporte financiero de un período.
  Future<ReportModel> generateReport({
    required int idUsuario,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double ingresoFijoActual,
  }) async {
    // Normaliza las fechas para trabajar con meses completos.
    final primerMes = DateTime(fechaInicio.year, fechaInicio.month);
    final ultimoMes = DateTime(fechaFin.year, fechaFin.month);

    // Consulta los ingresos y gastos del período.
    final incomes = await _reportRepository.getIncomesByPeriod(
      idUsuario: idUsuario,
      fechaInicio: _formatDate(fechaInicio),
      fechaFin: _formatDate(fechaFin.add(const Duration(days: 1))),
    );

    final expenses = await _reportRepository.getExpensesByPeriod(
      idUsuario: idUsuario,
      fechaInicio: _formatDate(fechaInicio),
      fechaFin: _formatDate(fechaFin.add(const Duration(days: 1))),
    );

    // Calcula los ingresos adicionales.
    double ingresosAdicionales = 0;

    for (final income in incomes) {
      if (income.tipo == 'ADICIONAL') {
        ingresosAdicionales += income.monto;
      }
    }

    // Calcula el ingreso fijo de cada mes del período.
    // No incluye meses futuros ni meses anteriores al primer historial.
    double ingresosFijos = 0;

    // Obtiene el último mes que puede contabilizarse.
    final hoy = DateTime.now();
    final ultimoMesDisponible = DateTime(hoy.year, hoy.month);

    DateTime mesActual = primerMes;

    while (!mesActual.isAfter(ultimoMes) &&
        !mesActual.isAfter(ultimoMesDisponible)) {
      // Consulta el ingreso fijo vigente para este mes.
      final history = await _reportRepository.getFixedIncomeByPeriod(
        idUsuario: idUsuario,
        periodStart: mesActual,
      );

      // Solo contabiliza el ingreso cuando existe historial.
      if (history != null) {
        ingresosFijos += history.monto;
      }

      // Avanza al siguiente mes.
      mesActual = DateTime(mesActual.year, mesActual.month + 1);
    }

    // Calcula el total de ingresos.
    final totalIngresos = ingresosFijos + ingresosAdicionales;

    // Calcula el total de gastos.
    double totalGastos = 0;

    for (final expense in expenses) {
      totalGastos += expense.monto;
    }

    // Agrupa los gastos por categoría.
    final categories = await _reportRepository.getCategories();

    final Map<int, double> gastosAgrupados = {};

    for (final expense in expenses) {
      gastosAgrupados.update(
        expense.idCategoria,
        (total) => total + expense.monto,
        ifAbsent: () => expense.monto,
      );
    }

    final gastosPorCategoria = gastosAgrupados.entries.map((entry) {
      final category = categories.firstWhere(
        (category) => category.idCategoria == entry.key,
        orElse: () =>
            throw StateError('No se encontró la categoría ${entry.key}.'),
      );

      return ReportCategoryModel(
        nombreCategoria: category.nombre,
        totalGastos: entry.value,
      );
    }).toList();

    // Calcula el saldo del período.
    final saldo = totalIngresos - totalGastos;

    return ReportModel(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      ingresoFijo: ingresosFijos,
      ingresosAdicionales: ingresosAdicionales,
      totalIngresos: totalIngresos,
      totalGastos: totalGastos,
      saldo: saldo,
      gastosPorCategoria: gastosPorCategoria,
    );
  }

  /// Convierte una fecha al formato utilizado por SQLite.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
