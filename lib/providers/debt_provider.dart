import 'package:flutter/foundation.dart';

import '../../../data/models/debt_model.dart';
import '../../../data/models/debt_payment_model.dart';
import '../data/services/debt_service.dart';
import '../../../data/models/debt_payment_preview_model.dart';

/// Provider encargado de administrar el estado del módulo Deudas.
///
/// Se comunica con DebtService y notifica a las pantallas
/// cuando los datos cambian.
class DebtProvider extends ChangeNotifier {
  final DebtService _debtService = DebtService();

  /// Lista de deudas del usuario.
  List<DebtModel> _debts = [];

  /// Lista de pagos de la deuda seleccionada.
  List<DebtPaymentModel> _payments = [];

  /// Indica si se está realizando una operación.
  bool _isLoading = false;

  /// Mensaje de error de la última operación.
  String? _errorMessage;

  /// Deudas disponibles para la interfaz.
  List<DebtModel> get debts => _debts;

  /// Pagos disponibles para la interfaz.
  List<DebtPaymentModel> get payments => _payments;

  /// Indica si hay una operación en progreso.
  bool get isLoading => _isLoading;

  /// Mensaje de error actual.
  String? get errorMessage => _errorMessage;

  /// Carga las deudas de un usuario.
  Future<void> loadDebts(int idUsuario) async {
    _setLoading(true);

    try {
      _clearError();
      _debts = await _debtService.getDebtsByUser(idUsuario);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Actualiza una deuda específica dentro de la lista del Provider.
  Future<void> _refreshDebtInList(int idDeuda) async {
    // Consulta los datos actualizados de la deuda en SQLite.
    final updatedDebt = await _debtService.getDebtById(idDeuda);

    if (updatedDebt == null) return;

    // Reemplaza la deuda anterior por su versión actualizada.
    _debts = _debts.map((debt) {
      return debt.idDeuda == idDeuda ? updatedDebt : debt;
    }).toList();
  }

  /// Obtiene una deuda específica.
  Future<DebtModel?> getDebtById(int idDeuda) async {
    try {
      _clearError();

      return await _debtService.getDebtById(idDeuda);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      return null;
    }
  }

  /// Registra una nueva deuda.
  Future<bool> createDebt(DebtModel debt) async {
    _setLoading(true);

    try {
      _clearError();
      await _debtService.createDebt(debt);
      await loadDebts(debt.idUsuario);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Actualiza una deuda existente.
  Future<bool> updateDebt(DebtModel debt) async {
    _setLoading(true);

    try {
      _clearError();
      await _debtService.updateDebt(debt);
      await loadDebts(debt.idUsuario);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Elimina una deuda.
  Future<bool> deleteDebt(int idDeuda, int idUsuario) async {
    _setLoading(true);

    try {
      _clearError();
      await _debtService.deleteDebt(idDeuda);
      await loadDebts(idUsuario);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Carga el historial de pagos de una deuda.
  Future<void> loadPayments(int idDeuda) async {
    _setLoading(true);

    try {
      _clearError();
      _payments = await _debtService.getPaymentsByDebt(idDeuda);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Calcula la distribución de un pago ordinario sin registrarlo.
  ///
  /// Delega los cálculos financieros a DebtService.
  Future<DebtPaymentPreviewModel?> previewPayment(
    DebtPaymentModel payment,
  ) async {
    try {
      _clearError();

      // Solicita al servicio la simulación del pago.
      final preview = await _debtService.previewPayment(payment);

      return preview;
    } catch (e) {
      // Conserva el mensaje de error para la interfaz.
      _errorMessage = e.toString();
      notifyListeners();

      return null;
    }
  }

  /// Registra un pago ordinario de una deuda.
  ///
  /// Actualiza el historial y la información de la deuda en la lista.
  Future<bool> registerPayment(DebtPaymentModel payment) async {
    _setLoading(true);

    try {
      _clearError();

      await _debtService.registerPayment(payment);

      // Actualiza el historial de pagos.
      _payments = await _debtService.getPaymentsByDebt(payment.idDeuda);

      // Actualiza la deuda en la lista principal.
      await _refreshDebtInList(payment.idDeuda);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registra un abono extraordinario directamente al capital.
  ///
  /// Actualiza el historial y la información de la deuda en la lista.
  Future<bool> registerExtraordinaryPayment(DebtPaymentModel payment) async {
    _setLoading(true);

    try {
      _clearError();

      await _debtService.registerExtraordinaryPayment(payment);

      // Actualiza el historial de movimientos de la deuda.
      _payments = await _debtService.getPaymentsByDebt(payment.idDeuda);

      // Actualiza la deuda en la lista principal.
      await _refreshDebtInList(payment.idDeuda);

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Limpia el mensaje de error.
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Actualiza el estado de carga y notifica a la interfaz.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Elimina el mensaje de error actual.
  void _clearError() {
    _errorMessage = null;
  }
}
