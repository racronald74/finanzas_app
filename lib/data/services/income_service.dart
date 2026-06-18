import '../models/income_model.dart';
import '../repositories/income_repository.dart';

// Servicio para manejar la lógica de negocio relacionada con ingresos
class IncomeService {
  final IncomeRepository _repository = IncomeRepository();

  Future<int> createIncome(IncomeModel income) async {
    _validateIncome(income);

    return await _repository.insertIncome(income);
  }

  Future<int> updateIncome(IncomeModel income) async {
    if (income.idIngreso == null) {
      throw ArgumentError('El ingreso no tiene identificador');
    }

    _validateIncome(income);

    return _repository.updateIncome(income);
  }

  Future<int> deleteIncome({
    required int idIngreso,
    required int idUsuario,
  }) async {
    return _repository.deleteIncome(idIngreso: idIngreso, idUsuario: idUsuario);
  }

  Future<List<IncomeModel>> getIncomesByUser(int idUsuario) async {
    return await _repository.getIncomesByUser(idUsuario);
  }

  /// Obtener ingreso fijo mensual
  Future<IncomeModel?> getFixedIncome(int idUsuario) async {
    return await _repository.getFixedIncome(idUsuario);
  }

  /// Obtener ingresos adicionales
  Future<List<IncomeModel>> getAdditionalIncomes(int idUsuario) async {
    return await _repository.getAdditionalIncomes(idUsuario);
  }

  void _validateIncome(IncomeModel income) {
    if (income.monto <= 0) {
      throw ArgumentError('El monto debe ser mayor a cero');
    }

    if (income.fecha.trim().isEmpty) {
      throw ArgumentError('La fecha es obligatoria');
    }

    if (income.idUsuario <= 0) {
      throw ArgumentError('Usuario invalido');
    }
  }
}
