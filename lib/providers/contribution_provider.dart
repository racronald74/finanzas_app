import 'package:flutter/material.dart';

import '../data/models/contribution_model.dart';
import '../data/services/contribution_service.dart';
import '../data/services/goal_service.dart';
import '../data/models/goal_model.dart';

/// Proveedor encargado de administrar el estado de los aportes.
class ContributionProvider extends ChangeNotifier {
  /// Servicio que contiene la lógica de negocio de los aportes.
  final ContributionService _contributionService = ContributionService();

  /// Servicio encargado de actualizar la meta
  /// después de registrar un aporte.
  final GoalService _goalService = GoalService();

  /// Lista de aportes cargados actualmente.
  List<ContributionModel> _contributions = [];

  /// Indica si existe una operación en curso.
  bool _isLoading = false;

  /// Mensaje de error de la última operación.
  String? _errorMessage;

  /// Lista de aportes disponibles para la interfaz.
  List<ContributionModel> get contributions => _contributions;

  /// Indica si se está ejecutando una operación.
  bool get isLoading => _isLoading;

  /// Mensaje de error actual.
  String? get errorMessage => _errorMessage;

  /// Registra un nuevo aporte y actualiza la meta.
  ///
  /// Primero obtiene la meta para validar que exista y conocer
  /// el usuario propietario. Después guarda el aporte y actualiza
  /// el monto acumulado de la meta.
  Future<bool> createContribution(ContributionModel contribution) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // Obtiene la meta antes de registrar el aporte.
      final GoalModel? goal = await _goalService.obtenerMetaPorIdMeta(
        contribution.idMeta,
      );

      if (goal == null) {
        throw ArgumentError('No se encontró la meta asociada al aporte.');
      }

      // Guarda el aporte en SQLite.
      await _contributionService.createContribution(contribution);

      // Actualiza el monto acumulado de la meta.
      await _goalService.actualizarMetaConAporte(
        idMeta: contribution.idMeta,
        idUsuario: goal.idUsuario,
        montoAporte: contribution.monto,
      );

      // Recarga los aportes de la meta.
      await loadContributions(contribution.idMeta);

      return true;
    } catch (error) {
      _errorMessage = error.toString();

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  /// Carga los aportes registrados para una meta.
  Future<void> loadContributions(int idMeta) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _contributions = await _contributionService.getContributionsByGoal(
        idMeta,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  /// Actualiza un aporte existente.
  Future<bool> updateContribution(ContributionModel contribution) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _contributionService.updateContribution(contribution);

      await loadContributions(contribution.idMeta);

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  /// Elimina un aporte existente.
  Future<bool> deleteContribution(ContributionModel contribution) async {
    if (contribution.idAporte == null) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _contributionService.deleteContribution(
        idAporte: contribution.idAporte!,
        idMeta: contribution.idMeta,
      );

      await loadContributions(contribution.idMeta);

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }
}
