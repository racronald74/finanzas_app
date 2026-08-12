import 'package:flutter/material.dart';

import '../data/models/goal_model.dart';
import '../data/services/goal_service.dart';

/// Proveedor encargado de administrar el estado de las metas.
class GoalProvider extends ChangeNotifier {
  final GoalService _goalService = GoalService();

  List<GoalModel> _goals = [];

  bool _isLoading = false;

  String? _errorMessage;

  /// Lista de metas registradas.
  List<GoalModel> get goals => _goals;

  /// Indica si existe una operación en curso.
  bool get isLoading => _isLoading;

  /// Mensaje de error de la última operación.
  String? get errorMessage => _errorMessage;

  /// Calcula el total ahorrado en todas las metas.
  double get totalSavings {
    double total = 0;

    for (final goal in _goals) {
      total += goal.savedAmount;
    }

    return total;
  }

  /// Cuenta las metas que actualmente están activas.
  int get activeGoals {
    return _goals.where((goal) => goal.status == 'Activa').length;
  }

  /// Calcula el progreso global de todas las metas.
  ///
  /// Se obtiene dividiendo el ahorro acumulado total
  /// entre el monto objetivo total.
  int get totalProgress {
    if (_goals.isEmpty) {
      return 0;
    }

    double totalTarget = 0;
    double totalSaved = 0;

    for (final goal in _goals) {
      totalTarget += goal.targetAmount;
      totalSaved += goal.savedAmount;
    }

    if (totalTarget <= 0) {
      return 0;
    }

    return ((totalSaved / totalTarget) * 100).round().clamp(0, 100);
  }

  /// Calcula el aporte mensual requerido para todas las metas activas.
  ///
  /// Suma el aporte mensual necesario de cada meta para alcanzar
  /// su objetivo dentro del tiempo restante.
  double get monthlyGoal {
    double total = 0;

    for (final goal in _goals) {
      // Solo se consideran las metas que todavía están activas.
      if (goal.status == 'Activa') {
        total += _goalService.calcularAporteMensual(goal);
      }
    }

    return total;
  }

  /// Crea una nueva meta.
  Future<bool> createGoal(GoalModel goal) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _goalService.crearMeta(goal);

      await loadGoals(goal.idUsuario);

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  /// Actualiza una meta existente.
  Future<bool> updateGoal(GoalModel goal) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _goalService.actualizarMeta(goal);

      await loadGoals(goal.idUsuario);

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  /// Elimina una meta.
  Future<bool> deleteGoal(GoalModel goal) async {
    if (goal.idMeta == null) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _goalService.eliminarMeta(
        idMeta: goal.idMeta!,
        idUsuario: goal.idUsuario,
      );

      await loadGoals(goal.idUsuario);

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  /// Carga las metas registradas de un usuario.
  Future<void> loadGoals(int idUsuario) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _goals = await _goalService.listarMetas(idUsuario);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  /// Carga únicamente las metas activas.
  Future<void> loadActiveGoals(int idUsuario) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _goals = await _goalService.listarMetasActivas(idUsuario);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  /// Carga únicamente las metas completadas.
  Future<void> loadCompletedGoals(int idUsuario) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _goals = await _goalService.listarMetasCompletadas(idUsuario);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }
}
