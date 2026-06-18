import '../models/income_model.dart';
import '../repositories/income_repository.dart';

// Servicio para manejar la lógica de negocio relacionada con ingresos
class IncomeService {
  final IncomeRepository _repository = IncomeRepository();

  Future<int> createIncome(IncomeModel income) async {
    return await _repository.insertIncome(income);
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
}
