import 'package:flutter/material.dart';

import '../data/models/obligation_model.dart';
import '../data/services/obligation_service.dart';

/// Provider encargado de administrar el estado
/// del módulo Obligaciones.
///
/// Es el intermediario entre la interfaz y el
/// servicio de Obligaciones.
class ObligationProvider extends ChangeNotifier {
  /// Servicio del módulo Obligaciones.
  final ObligationService _obligationService = ObligationService();

  /// Lista de obligaciones del usuario.
  List<ObligationModel> _obligations = [];

  /// Indica si existe una operación en ejecución.
  bool _isLoading = false;

  /// Mensaje de error para mostrar en pantalla.
  String _errorMessage = '';

  /// Lectura pública de las obligaciones.
  List<ObligationModel> get obligations => _obligations;

  /// Estado de carga.
  bool get isLoading => _isLoading;

  /// Último mensaje de error.
  String get errorMessage => _errorMessage;

  /// Registrar una nueva obligación.
  Future<bool> createObligation(ObligationModel obligation) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _obligationService.createObligation(obligation);

      await loadObligations(obligation.idUsuario);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  /// Obtener las obligaciones del usuario.
  Future<void> loadObligations(int idUsuario) async {
    _obligations = await _obligationService.getObligationsByUser(idUsuario);

    notifyListeners();
  }

  /// Actualizar una obligación existente.
  Future<bool> updateObligation(ObligationModel obligation) async {
    try {
      await _obligationService.updateObligation(obligation);

      await loadObligations(obligation.idUsuario);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      return false;
    }
  }

  /// Eliminar una obligación.
  Future<void> deleteObligation(int idObligacion, int idUsuario) async {
    await _obligationService.deleteObligation(idObligacion);

    await loadObligations(idUsuario);
  }

  /// Obligaciones pendientes.
  List<ObligationModel> get pendingObligations {
    return _obligations
        .where(
          (obligation) =>
              obligation.estado == ObligationService.estadoPendiente,
        )
        .toList();
  }

  /// Obligaciones pagadas.
  List<ObligationModel> get paidObligations {
    return _obligations
        .where(
          (obligation) => obligation.estado == ObligationService.estadoPagada,
        )
        .toList();
  }

  /// Total de obligaciones pendientes.
  double get totalPending {
    double total = 0;

    for (final obligation in pendingObligations) {
      total += obligation.monto;
    }

    return total;
  }

  /// Total comprometido por todas las obligaciones registradas.
  double get totalCommitted {
    double total = 0;

    for (final obligation in pendingObligations) {
      total += obligation.monto;
    }

    return total;
  }

  /// Total de obligaciones pagadas.
  double get totalPaid {
    double total = 0;

    for (final obligation in paidObligations) {
      total += obligation.monto;
    }

    return total;
  }

  /// Marca una obligación como pagada.
  ///
  /// El servicio genera el gasto asociado dentro
  /// de una transacción y actualiza la obligación.
  Future<bool> markAsPaid(ObligationModel obligation) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _obligationService.markAsPaid(obligation);

      await loadObligations(obligation.idUsuario);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();

      return false;
    }
  }
}
