import 'package:flutter/material.dart';

import '../data/models/report_model.dart';
import '../data/services/report_service.dart';

/// Provider encargado de administrar el estado
/// y la generación de los reportes financieros.
class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  // Resultado del reporte generado.
  ReportModel? _report;

  // Estado de carga.
  bool _isLoading = false;

  // Mensaje de error.
  String? _errorMessage;

  ReportModel? get report => _report;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  /// Genera un reporte para el período seleccionado.
  Future<void> generateReport({
    required int idUsuario,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double ingresoFijoActual,
  }) async {
    // Activa el estado de carga y limpia errores anteriores.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Solicita los cálculos al servicio.
      _report = await _reportService.generateReport(
        idUsuario: idUsuario,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        ingresoFijoActual: ingresoFijoActual,
      );
    } catch (e) {
      // Guarda el error para mostrarlo en la interfaz.
      _errorMessage = 'No fue posible generar el reporte: $e';
      _report = null;
    } finally {
      // Finaliza la carga y actualiza la interfaz.
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia el reporte y los mensajes de error.
  void clearReport() {
    _report = null;
    _errorMessage = null;
    notifyListeners();
  }
}
