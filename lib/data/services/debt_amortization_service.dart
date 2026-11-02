import 'dart:math' as math;

/// Servicio encargado de realizar los cálculos financieros
/// de las deudas mediante el sistema de amortización francés.
class DebtAmortizationService {
  /// Convierte una tasa efectiva anual porcentual
  /// en una tasa efectiva mensual decimal.
  double calculateMonthlyRate(double annualRatePercentage) {
    if (annualRatePercentage < 0) {
      throw ArgumentError('La tasa anual no puede ser negativa.');
    }

    // Convierte el porcentaje a valor decimal.
    final annualRate = annualRatePercentage / 100;

    // Calcula la tasa efectiva mensual.
    return math.pow(1 + annualRate, 1 / 12).toDouble() - 1;
  }

  /// Calcula la cuota mensual fija mediante el sistema francés.
  double calculateMonthlyInstallment({
    required double principal,
    required double monthlyRate,
    required int termInMonths,
  }) {
    if (principal <= 0) {
      throw ArgumentError('El capital debe ser mayor a cero.');
    }

    if (monthlyRate < 0) {
      throw ArgumentError('La tasa mensual no puede ser negativa.');
    }

    if (termInMonths <= 0) {
      throw ArgumentError('El plazo debe ser mayor a cero.');
    }

    // Si no hay intereses, divide el capital entre las cuotas.
    if (monthlyRate == 0) {
      return principal / termInMonths;
    }

    // Calcula el factor de capitalización.
    final factor = math.pow(1 + monthlyRate, termInMonths).toDouble();

    // Aplica la fórmula de amortización francesa.
    return principal * (monthlyRate * factor) / (factor - 1);
  }

  /// Calcula los intereses sobre el capital inicial del período.
  double calculatePeriodInterest({
    required double openingBalance,
    required double monthlyRate,
  }) {
    if (openingBalance < 0 || monthlyRate < 0) {
      throw ArgumentError('Los valores no pueden ser negativos.');
    }

    return openingBalance * monthlyRate;
  }

  /// Calcula la parte de la cuota destinada al capital.
  double calculatePeriodPrincipal({
    required double installment,
    required double interest,
  }) {
    if (installment < 0 || interest < 0) {
      throw ArgumentError('Los valores no pueden ser negativos.');
    }

    return installment - interest;
  }

  /// Calcula el capital restante después de un pago.
  double calculateRemainingCapital({
    required double openingBalance,
    required double principalPayment,
  }) {
    if (openingBalance < 0 || principalPayment < 0) {
      throw ArgumentError('Los valores no pueden ser negativos.');
    }

    // Evita que el saldo de capital quede negativo.
    final remaining = openingBalance - principalPayment;

    return remaining < 0 ? 0 : remaining;
  }

  /// Calcula el nuevo plazo conservando la cuota mensual actual.
  ///
  /// Se utiliza cuando el usuario selecciona REDUCIR_PLAZO.
  int calculateReducedTerm({
    required double principal,
    required double monthlyRate,
    required double installment,
  }) {
    if (principal <= 0) {
      throw ArgumentError('El capital debe ser mayor a cero.');
    }

    if (monthlyRate < 0) {
      throw ArgumentError('La tasa mensual no puede ser negativa.');
    }

    if (installment <= 0) {
      throw ArgumentError('La cuota debe ser mayor a cero.');
    }

    // Calcula los intereses del primer período.
    final firstInterest = principal * monthlyRate;

    // La cuota debe cubrir al menos los intereses del período.
    if (installment <= firstInterest) {
      throw ArgumentError(
        'La cuota no permite amortizar el capital pendiente.',
      );
    }

    var remainingCapital = principal;
    var remainingMonths = 0;

    // Simula los pagos hasta cancelar completamente el capital.
    while (remainingCapital > 0) {
      // Calcula los intereses del período actual.
      final periodInterest = remainingCapital * monthlyRate;

      // Determina cuánto de la cuota reduce el capital.
      final principalPayment = installment - periodInterest;

      if (principalPayment <= 0) {
        throw ArgumentError(
          'La cuota no permite amortizar el capital pendiente.',
        );
      }

      // Actualiza el capital sin permitir saldos negativos.
      remainingCapital -= principalPayment;

      if (remainingCapital < 0) {
        remainingCapital = 0;
      }

      // Cuenta la cuota necesaria para el período.
      remainingMonths++;
    }

    return remainingMonths;
  }

  /// Calcula la nueva cuota conservando el plazo restante.
  ///
  /// Se utiliza cuando el usuario selecciona REDUCIR_CUOTA.
  double calculateReducedInstallment({
    required double principal,
    required double monthlyRate,
    required int remainingTermInMonths,
  }) {
    // Reutiliza la fórmula de amortización francesa.
    return calculateMonthlyInstallment(
      principal: principal,
      monthlyRate: monthlyRate,
      termInMonths: remainingTermInMonths,
    );
  }
}
