import '../models/contribution_model.dart';
import '../repositories/contribution_repository.dart';

/// Servicio encargado de manejar la lógica de negocio
/// relacionada con los aportes de las metas.
class ContributionService {
  /// Repositorio utilizado para acceder a SQLite.
  final ContributionRepository _repository = ContributionRepository();

  /// Registra un nuevo aporte.
  ///
  /// Valida la información antes de enviarla al repositorio.
  Future<int> createContribution(ContributionModel contribution) async {
    _validateContribution(contribution);

    return await _repository.insertContribution(contribution);
  }

  /// Obtiene todos los aportes registrados para una meta.
  Future<List<ContributionModel>> getContributionsByGoal(int idMeta) async {
    if (idMeta <= 0) {
      throw ArgumentError('La meta no es válida');
    }

    return await _repository.getContributionsByGoal(idMeta);
  }

  /// Actualiza un aporte existente.
  Future<int> updateContribution(ContributionModel contribution) async {
    if (contribution.idAporte == null) {
      throw ArgumentError('El aporte no tiene identificador');
    }

    _validateContribution(contribution);

    return await _repository.updateContribution(contribution);
  }

  /// Elimina un aporte existente.
  Future<int> deleteContribution({
    required int idAporte,
    required int idMeta,
  }) async {
    if (idAporte <= 0) {
      throw ArgumentError('El aporte no es válido');
    }

    if (idMeta <= 0) {
      throw ArgumentError('La meta no es válida');
    }

    return await _repository.deleteContribution(
      idAporte: idAporte,
      idMeta: idMeta,
    );
  }

  /// Valida los datos necesarios para registrar o actualizar
  /// un aporte.
  void _validateContribution(ContributionModel contribution) {
    // El aporte debe tener un valor positivo.
    if (contribution.monto <= 0) {
      throw ArgumentError('El monto del aporte debe ser mayor que cero');
    }

    // La fecha es obligatoria.
    if (contribution.fecha.trim().isEmpty) {
      throw ArgumentError('La fecha del aporte es obligatoria');
    }

    // La meta debe existir.
    if (contribution.idMeta <= 0) {
      throw ArgumentError('La meta no es válida');
    }

    // El origen o método del aporte es obligatorio.
    if (contribution.origen.trim().isEmpty) {
      throw ArgumentError('El método del aporte es obligatorio');
    }
  }
}
