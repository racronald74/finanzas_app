import 'package:sqflite/sqflite.dart';

import '../../../data/database/database_helper.dart';
import '../../../data/models/debt_model.dart';
import '../../../data/models/debt_payment_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/repositories/debt_repository.dart';
import '../../../data/repositories/expense_repository.dart';
import 'debt_amortization_service.dart';
import '../models/debt_payment_preview_model.dart';

/// Servicio encargado de la lógica de negocio de las Deudas.
///
/// Coordina las operaciones entre los repositorios y aplica
/// las reglas de negocio definidas para el módulo.
class DebtService {
  final DebtRepository _debtRepository = DebtRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Servicio encargado de los cálculos de amortización.
  final DebtAmortizationService _amortizationService =
      DebtAmortizationService();

  // ---------------------------------------------------------------------------
  // DEUDAS
  // ---------------------------------------------------------------------------

  /// Registra una nueva deuda calculando sus condiciones financieras.
  Future<int> createDebt(DebtModel debt) async {
    // Valida los datos antes de realizar los cálculos.
    _validateDebt(debt);

    // Convierte la tasa efectiva anual a tasa mensual.
    final monthlyRate = _amortizationService.calculateMonthlyRate(
      debt.tasaInteresEA,
    );

    // Calcula la cuota mensual cuando existe un plazo definido.
    final cuotaMensual = debt.plazo != null
        ? _amortizationService.calculateMonthlyInstallment(
            principal: debt.montoTotal,
            monthlyRate: monthlyRate,
            termInMonths: debt.plazo!,
          )
        : null;

    // Inicializa el capital y el saldo pendiente con el monto total.
    final nuevaDeuda = debt.copyWith(
      saldoCapital: debt.montoTotal,
      capitalInicioPeriodo: debt.montoTotal,
      saldoPendiente: debt.montoTotal,
      cuotaMensual: cuotaMensual,
    );

    // Guarda la deuda con sus condiciones financieras calculadas.
    return await _debtRepository.insertDebt(nuevaDeuda);
  }

  /// Obtiene todas las deudas de un usuario.
  Future<List<DebtModel>> getDebtsByUser(int idUsuario) async {
    return await _debtRepository.getDebtsByUser(idUsuario);
  }

  /// Obtiene el detalle de una deuda.
  Future<DebtModel?> getDebtById(int idDeuda) async {
    return await _debtRepository.getDebtById(idDeuda);
  }

  /// Actualiza una deuda existente.
  Future<int> updateDebt(DebtModel debt) async {
    _validateDebt(debt);

    return await _debtRepository.updateDebt(debt);
  }

  /// Elimina una deuda.
  Future<int> deleteDebt(int idDeuda) async {
    final debt = await _debtRepository.getDebtById(idDeuda);

    if (debt == null) {
      throw Exception('La deuda no existe.');
    }

    return await _debtRepository.deleteDebt(idDeuda);
  }

  // ---------------------------------------------------------------------------
  // PAGOS
  // ---------------------------------------------------------------------------

  /// Simula la distribución de un pago ordinario sin registrar cambios.
  ///
  /// Utiliza las mismas reglas financieras de registerPayment:
  /// primero calcula los intereses vencidos y después distribuye
  /// el pago entre intereses y capital.
  Future<DebtPaymentPreviewModel> previewPayment(
    DebtPaymentModel payment,
  ) async {
    // Valida los datos básicos del pago.
    _validatePayment(payment);

    // Consulta la deuda sin modificarla.
    final debt = await _debtRepository.getDebtById(payment.idDeuda);

    if (debt == null) {
      throw Exception('La deuda no existe.');
    }

    if (debt.estado == 'Pagada') {
      throw Exception('La deuda ya se encuentra pagada.');
    }

    // Normaliza las fechas para comparar únicamente día, mes y año.
    final startDate = _parseDateOnly(debt.fechaInicio);
    final paymentDate = _parseDateOnly(payment.fecha);

    // Impide simular pagos anteriores al inicio de la deuda.
    if (paymentDate.isBefore(startDate)) {
      throw Exception(
        'La fecha del pago no puede ser anterior al inicio de la deuda.',
      );
    }

    // Obtiene la fecha del último cálculo de intereses.
    final lastCalculationDate = debt.fechaUltimoCalculoIntereses != null
        ? _parseDateOnly(debt.fechaUltimoCalculoIntereses!)
        : startDate;

    // Calcula los períodos mensuales vencidos.
    final elapsedPeriods = _calculateElapsedPeriods(
      startDate: startDate,
      lastCalculationDate: lastCalculationDate,
      paymentDate: paymentDate,
    );

    // Convierte la tasa efectiva anual a tasa mensual.
    final monthlyRate = _amortizationService.calculateMonthlyRate(
      debt.tasaInteresEA,
    );

    // Conserva los intereses pendientes existentes.
    var pendingInterest = debt.interesesPendientes;

    // Obtiene el capital de referencia del período.
    var referenceCapital = debt.capitalInicioPeriodo;

    // Busca el siguiente aniversario mensual pendiente.
    var monthOffset = 1;
    var nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);

    while (!nextPeriodDate.isAfter(lastCalculationDate)) {
      monthOffset++;
      nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);
    }

    // Calcula los intereses de los períodos vencidos.
    for (var i = 0; i < elapsedPeriods; i++) {
      final periodInterest = _amortizationService.calculatePeriodInterest(
        openingBalance: referenceCapital,
        monthlyRate: monthlyRate,
      );

      // Acumula los intereses redondeados a dos decimales.
      pendingInterest = _roundCurrency(
        pendingInterest + _roundCurrency(periodInterest),
      );

      // Los siguientes períodos utilizan el capital vigente.
      referenceCapital = debt.saldoCapital;

      monthOffset++;
      nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);
    }

    // Calcula el saldo disponible incluyendo intereses.
    final availableBalance = _roundCurrency(
      debt.saldoCapital + pendingInterest,
    );

    // Normaliza el importe del pago.
    final paymentAmount = _roundCurrency(payment.monto);

    // Valida que el pago no supere el saldo actualizado.
    if (paymentAmount > availableBalance) {
      throw Exception('El pago no puede ser mayor al saldo pendiente.');
    }

    // Distribuye el pago primero entre intereses y después capital.
    final distribution = _distributePayment(
      paymentAmount: paymentAmount,
      pendingInterest: pendingInterest,
      capitalBalance: debt.saldoCapital,
    );

    final interestPayment = distribution['interesesPagados']!;
    final principalPayment = distribution['abonoCapital']!;

    // Calcula los intereses que permanecerán pendientes.
    final remainingInterest = _roundCurrency(pendingInterest - interestPayment);

    // Calcula el capital que permanecerá pendiente.
    final remainingCapital = _roundCurrency(
      debt.saldoCapital - principalPayment,
    );

    // Calcula el saldo total después del pago.
    final remainingBalance = _roundCurrency(
      remainingCapital + remainingInterest,
    );

    // Devuelve los resultados sin modificar la base de datos.
    return DebtPaymentPreviewModel(
      montoPago: paymentAmount,
      interesesPagados: interestPayment,
      abonoCapital: principalPayment,
      interesesRestantes: remainingInterest,
      capitalRestante: remainingCapital,
      saldoRestante: remainingBalance,
      pagoInferiorCuota:
          debt.cuotaMensual != null && paymentAmount < debt.cuotaMensual!,
    );
  }

  /// Registra un pago ordinario sobre una deuda.
  ///
  /// El proceso se realiza dentro de una única transacción:
  ///
  /// 1. Calcula los intereses de los períodos vencidos.
  /// 2. Distribuye el pago entre intereses y capital.
  /// 3. Registra el pago con su distribución financiera.
  /// 4. Actualiza los saldos y el estado de la deuda.
  /// 5. Genera el gasto automático correspondiente.
  Future<int> registerPayment(DebtPaymentModel payment) async {
    _validatePayment(payment);

    return await _databaseHelper.transaction<int>((transaction) async {
      // Consulta la deuda dentro de la transacción.
      final debt = await _debtRepository.getDebtById(
        payment.idDeuda,
        executor: transaction,
      );

      if (debt == null) {
        throw Exception('La deuda no existe.');
      }

      if (debt.estado == 'Pagada') {
        throw Exception('La deuda ya se encuentra pagada.');
      }

      // Normaliza las fechas para comparar únicamente día, mes y año.
      final startDate = _parseDateOnly(debt.fechaInicio);
      final paymentDate = _parseDateOnly(payment.fecha);

      // No permite pagos anteriores al inicio de la deuda.
      if (paymentDate.isBefore(startDate)) {
        throw Exception(
          'La fecha del pago no puede ser anterior al inicio de la deuda.',
        );
      }

      // Obtiene la fecha del último cálculo de intereses.
      final lastCalculationDate = debt.fechaUltimoCalculoIntereses != null
          ? _parseDateOnly(debt.fechaUltimoCalculoIntereses!)
          : startDate;

      // Calcula los períodos mensuales que ya finalizaron.
      final elapsedPeriods = _calculateElapsedPeriods(
        startDate: startDate,
        lastCalculationDate: lastCalculationDate,
        paymentDate: paymentDate,
      );

      // Obtiene la tasa mensual equivalente a la tasa E.A.
      final monthlyRate = _amortizationService.calculateMonthlyRate(
        debt.tasaInteresEA,
      );

      // Conserva los intereses pendientes anteriores.
      var pendingInterest = debt.interesesPendientes;

      // El primer período utiliza el capital guardado como referencia.
      var referenceCapital = debt.capitalInicioPeriodo;

      // Conserva la última fecha hasta la que se calcularon intereses.
      var updatedCalculationDate = debt.fechaUltimoCalculoIntereses;

      // Busca el primer aniversario posterior al último cálculo.
      var monthOffset = 1;
      var nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);

      while (!nextPeriodDate.isAfter(lastCalculationDate)) {
        monthOffset++;
        nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);
      }

      // Calcula los intereses de cada período mensual vencido.
      for (var i = 0; i < elapsedPeriods; i++) {
        // Calcula intereses sobre el capital de referencia del período.
        final periodInterest = _amortizationService.calculatePeriodInterest(
          openingBalance: referenceCapital,
          monthlyRate: monthlyRate,
        );

        // Redondea los intereses generados a dos decimales.
        final roundedInterest = _roundCurrency(periodInterest);

        // Acumula los intereses sin capitalizarlos.
        pendingInterest = _roundCurrency(pendingInterest + roundedInterest);

        // Actualiza la fecha del último período calculado.
        updatedCalculationDate = _formatDate(nextPeriodDate);

        // Para los períodos siguientes utiliza el capital vigente.
        referenceCapital = debt.saldoCapital;

        // Avanza al siguiente aniversario mensual.
        monthOffset++;
        nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);
      }

      // Calcula el saldo total después de generar intereses.
      final availableBalance = _roundCurrency(
        debt.saldoCapital + pendingInterest,
      );

      // Normaliza el importe del pago a dos decimales.
      final paymentAmount = _roundCurrency(payment.monto);

      // Impide realizar pagos superiores al saldo actualizado.
      if (paymentAmount > availableBalance) {
        throw Exception('El pago no puede ser mayor al saldo pendiente.');
      }

      // Distribuye el pago primero entre intereses y después entre capital.
      final distribution = _distributePayment(
        paymentAmount: paymentAmount,
        pendingInterest: pendingInterest,
        capitalBalance: debt.saldoCapital,
      );

      final interestPayment = distribution['interesesPagados']!;
      final principalPayment = distribution['abonoCapital']!;

      // Actualiza los intereses pendientes.
      final updatedPendingInterest = _roundCurrency(
        pendingInterest - interestPayment,
      );

      // Actualiza el capital pendiente.
      final updatedCapital = _roundCurrency(
        debt.saldoCapital - principalPayment,
      );

      // Calcula el nuevo saldo total.
      final updatedBalance = _roundCurrency(
        updatedCapital + updatedPendingInterest,
      );

      // Si se generaron nuevos períodos, el capital vigente antes
      // del pago será la referencia del período mensual actual.
      final updatedReferenceCapital = elapsedPeriods > 0
          ? debt.saldoCapital
          : debt.capitalInicioPeriodo;

      // La deuda queda pagada cuando capital e intereses llegan a cero.
      final newStatus = updatedBalance == 0 ? 'Pagada' : 'Activa';

      // Construye el registro con la distribución real del pago.
      final registeredPayment = payment.copyWith(
        monto: paymentAmount,
        abonoCapital: principalPayment,
        interesesPagados: interestPayment,
      );

      // Registra el pago dentro de la transacción.
      final paymentId = await _debtRepository.insertPayment(
        registeredPayment,
        executor: transaction,
      );

      // Actualiza los saldos y las fechas de cálculo de la deuda.
      final updatedDebt = debt.copyWith(
        saldoCapital: updatedCapital,
        interesesPendientes: updatedPendingInterest,
        saldoPendiente: updatedBalance,
        capitalInicioPeriodo: updatedReferenceCapital,
        fechaUltimoCalculoIntereses: updatedCalculationDate,
        estado: newStatus,
      );

      await _debtRepository.updateDebt(updatedDebt, executor: transaction);

      // Busca la categoría de sistema "Pago de deuda".
      final categoryId = await _getDebtPaymentCategoryId(transaction);

      // Genera el gasto por el importe total del pago.
      final expense = ExpenseModel(
        nombre: 'Pago de deuda',
        monto: paymentAmount,
        fecha: payment.fecha,
        descripcion: payment.descripcion ?? '',
        idCategoria: categoryId,
        idUsuario: debt.idUsuario,
        origen: 'DEUDA',
        fechaRegistro: payment.fechaRegistro,
      );

      await _expenseRepository.insertExpense(expense, executor: transaction);

      return paymentId;
    });
  }

  /// Obtiene el historial de pagos de una deuda.
  Future<List<DebtPaymentModel>> getPaymentsByDebt(int idDeuda) async {
    return await _debtRepository.getPaymentsByDebt(idDeuda);
  }

  /// Registra un abono extraordinario directamente al capital.
  ///
  /// Primero calcula los intereses de los períodos vencidos.
  /// Después aplica el abono y recalcula el plazo o la cuota.
  Future<int> registerExtraordinaryPayment(DebtPaymentModel payment) async {
    _validatePayment(payment);

    // Valida la opción de amortización seleccionada.
    if (!['REDUCIR_PLAZO', 'REDUCIR_CUOTA'].contains(payment.opcionAbono)) {
      throw Exception('La opción del abono extraordinario no es válida.');
    }

    return await _databaseHelper.transaction<int>((transaction) async {
      // Consulta la deuda dentro de la transacción.
      final debt = await _debtRepository.getDebtById(
        payment.idDeuda,
        executor: transaction,
      );

      if (debt == null) {
        throw Exception('La deuda no existe.');
      }

      if (debt.estado == 'Pagada') {
        throw Exception('La deuda ya se encuentra pagada.');
      }

      // Normaliza las fechas para comparar únicamente el día.
      final startDate = _parseDateOnly(debt.fechaInicio);
      final paymentDate = _parseDateOnly(payment.fecha);

      if (paymentDate.isBefore(startDate)) {
        throw Exception(
          'La fecha del abono no puede ser anterior al inicio de la deuda.',
        );
      }

      // Redondea el importe del abono a dos decimales.
      final paymentAmount = _roundCurrency(payment.monto);

      // El abono no puede superar el capital pendiente.
      if (paymentAmount > debt.saldoCapital) {
        throw Exception('El abono no puede ser mayor al capital pendiente.');
      }

      // Obtiene la fecha del último cálculo de intereses.
      final lastCalculationDate = debt.fechaUltimoCalculoIntereses != null
          ? _parseDateOnly(debt.fechaUltimoCalculoIntereses!)
          : startDate;

      // Calcula los períodos mensuales vencidos.
      final elapsedPeriods = _calculateElapsedPeriods(
        startDate: startDate,
        lastCalculationDate: lastCalculationDate,
        paymentDate: paymentDate,
      );

      // Obtiene la tasa mensual equivalente.
      final monthlyRate = _amortizationService.calculateMonthlyRate(
        debt.tasaInteresEA,
      );

      // Conserva los intereses pendientes anteriores.
      var pendingInterest = debt.interesesPendientes;

      // Utiliza el capital de referencia del período actual.
      var referenceCapital = debt.capitalInicioPeriodo;

      // Conserva la fecha del último cálculo.
      var updatedCalculationDate = debt.fechaUltimoCalculoIntereses;

      // Busca el siguiente aniversario mensual pendiente.
      var monthOffset = 1;
      var nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);

      while (!nextPeriodDate.isAfter(lastCalculationDate)) {
        monthOffset++;
        nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);
      }

      // Calcula los intereses de los períodos que ya finalizaron.
      for (var i = 0; i < elapsedPeriods; i++) {
        final periodInterest = _amortizationService.calculatePeriodInterest(
          openingBalance: referenceCapital,
          monthlyRate: monthlyRate,
        );

        // Acumula los intereses sin capitalizarlos.
        pendingInterest = _roundCurrency(
          pendingInterest + _roundCurrency(periodInterest),
        );

        // Actualiza la fecha del último período calculado.
        updatedCalculationDate = _formatDate(nextPeriodDate);

        // Los períodos siguientes utilizan el capital vigente.
        referenceCapital = debt.saldoCapital;

        monthOffset++;
        nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);
      }

      // Valida el abono contra el capital disponible.
      final paymentAmountRounded = paymentAmount;

      // Aplica el abono directamente al capital.
      final updatedCapital = _roundCurrency(
        debt.saldoCapital - paymentAmountRounded,
      );

      // Conserva los intereses pendientes sin modificarlos.
      final updatedBalance = _roundCurrency(updatedCapital + pendingInterest);

      // Calcula los períodos transcurridos desde el inicio.
      final totalElapsedPeriods = _calculateElapsedPeriods(
        startDate: startDate,
        lastCalculationDate: startDate,
        paymentDate: paymentDate,
      );

      // Calcula los meses restantes del plazo.
      final remainingTerm = debt.plazo != null
          ? debt.plazo! - totalElapsedPeriods
          : null;

      var updatedTerm = debt.plazo;
      var updatedInstallment = debt.cuotaMensual;

      // Recalcula las condiciones de amortización.
      if (updatedCapital > 0) {
        if (payment.opcionAbono == 'REDUCIR_PLAZO') {
          // Mantiene la cuota y reduce el número de períodos.
          if (debt.cuotaMensual == null || debt.plazo == null) {
            throw Exception(
              'La deuda no tiene condiciones de amortización definidas.',
            );
          }

          if (remainingTerm == null || remainingTerm <= 0) {
            throw Exception(
              'No existen cuotas pendientes para reducir el plazo.',
            );
          }

          final newRemainingTerm = _amortizationService.calculateReducedTerm(
            principal: updatedCapital,
            monthlyRate: monthlyRate,
            installment: debt.cuotaMensual!,
          );

          updatedTerm = totalElapsedPeriods + newRemainingTerm;
        } else {
          // Mantiene el plazo final y reduce el valor de la cuota.
          if (debt.plazo == null ||
              remainingTerm == null ||
              remainingTerm <= 0) {
            throw Exception(
              'No existen cuotas pendientes para recalcular la cuota.',
            );
          }

          updatedInstallment = _amortizationService.calculateReducedInstallment(
            principal: updatedCapital,
            monthlyRate: monthlyRate,
            remainingTermInMonths: remainingTerm,
          );
        }
      }

      // Determina el capital de referencia del período actual.
      //
      // Si ya terminó un período, o el abono se realiza exactamente
      // en la fecha de referencia, el nuevo capital inicia el período.
      //
      // Si el abono ocurre a mitad del período, se conserva el capital
      // anterior para no modificar los intereses de ese período.
      final updatedReferenceCapital =
          elapsedPeriods > 0 || !paymentDate.isAfter(lastCalculationDate)
          ? updatedCapital
          : debt.capitalInicioPeriodo;

      // La deuda queda pagada cuando el capital llega a cero.
      final newStatus = updatedCapital == 0 ? 'Pagada' : 'Activa';

      // Construye el movimiento extraordinario.
      final registeredPayment = payment.copyWith(
        monto: paymentAmountRounded,
        abonoCapital: paymentAmountRounded,
        interesesPagados: 0,
        tipoPago: 'EXTRAORDINARIO',
      );

      // Registra el movimiento dentro de la transacción.
      final paymentId = await _debtRepository.insertPayment(
        registeredPayment,
        executor: transaction,
      );

      // Actualiza la deuda con los nuevos valores financieros.
      final updatedDebt = debt.copyWith(
        saldoCapital: updatedCapital,
        capitalInicioPeriodo: updatedReferenceCapital,
        interesesPendientes: pendingInterest,
        saldoPendiente: updatedBalance,
        fechaUltimoCalculoIntereses: updatedCalculationDate,
        plazo: updatedTerm,
        cuotaMensual: updatedInstallment,
        estado: newStatus,
      );

      await _debtRepository.updateDebt(updatedDebt, executor: transaction);

      // Obtiene la categoría utilizada para los gastos de deuda.
      final categoryId = await _getDebtPaymentCategoryId(transaction);

      // Registra el gasto por el importe total del abono.
      final expense = ExpenseModel(
        nombre: 'Abono extraordinario a deuda',
        monto: paymentAmountRounded,
        fecha: payment.fecha,
        descripcion: payment.descripcion ?? '',
        idCategoria: categoryId,
        idUsuario: debt.idUsuario,
        origen: 'DEUDA',
        fechaRegistro: payment.fechaRegistro,
      );

      await _expenseRepository.insertExpense(expense, executor: transaction);

      return paymentId;
    });
  }

  // ---------------------------------------------------------------------------
  // VALIDACIONES
  // ---------------------------------------------------------------------------

  /// Valida los datos principales de una deuda.
  void _validateDebt(DebtModel debt) {
    if (debt.acreedor.trim().isEmpty) {
      throw Exception('El acreedor es obligatorio.');
    }

    if (debt.montoTotal <= 0) {
      throw Exception('El monto total debe ser mayor a cero.');
    }

    if (debt.saldoPendiente < 0) {
      throw Exception('El saldo pendiente no puede ser negativo.');
    }

    // Valida que la tasa efectiva anual no sea negativa.
    if (debt.tasaInteresEA < 0) {
      throw Exception('La tasa de interés E.A. no puede ser negativa.');
    }

    if (debt.plazo != null && debt.plazo! <= 0) {
      throw Exception('El plazo debe ser mayor a cero.');
    }

    if (debt.idUsuario <= 0) {
      throw Exception('El usuario de la deuda no es válido.');
    }
  }

  /// Valida los datos de un pago.
  void _validatePayment(DebtPaymentModel payment) {
    if (payment.monto <= 0) {
      throw Exception('El monto del pago debe ser mayor a cero.');
    }

    if (payment.idDeuda <= 0) {
      throw Exception('La deuda asociada no es válida.');
    }
  }

  // ---------------------------------------------------------------------------
  // CATEGORÍA DEL GASTO AUTOMÁTICO
  // ---------------------------------------------------------------------------

  /// Obtiene el ID de la categoría de sistema utilizada
  /// para los gastos generados por pagos de deuda.
  Future<int> _getDebtPaymentCategoryId(DatabaseExecutor transaction) async {
    final result = await transaction.query(
      'categoria',
      columns: ['id_categoria'],
      where: 'nombre = ? AND tipo = ? AND es_sistema = 1',
      whereArgs: ['Pago de deuda', 'GASTO'],
      limit: 1,
    );

    if (result.isEmpty) {
      throw Exception('No existe la categoría de sistema "Pago de deuda".');
    }

    return result.first['id_categoria'] as int;
  }

  // ---------------------------------------------------------------------------
  // CÁLCULO DE PERÍODOS E INTERESES
  // ---------------------------------------------------------------------------

  /// Calcula los períodos mensuales vencidos desde la fecha
  /// del último cálculo hasta la fecha del pago.
  ///
  /// Cada período conserva como referencia el día original
  /// de inicio de la deuda.
  int _calculateElapsedPeriods({
    required DateTime startDate,
    required DateTime lastCalculationDate,
    required DateTime paymentDate,
  }) {
    // No calcula intereses antes del inicio de la deuda.
    if (paymentDate.isBefore(startDate)) {
      return 0;
    }

    var periods = 0;
    var monthOffset = 1;

    // Obtiene el siguiente aniversario mensual desde el inicio.
    var nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);

    // Omite los períodos que ya fueron calculados.
    while (!nextPeriodDate.isAfter(lastCalculationDate)) {
      monthOffset++;
      nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);
    }

    // Cuenta los períodos que ya finalizaron a la fecha del pago.
    while (!nextPeriodDate.isAfter(paymentDate)) {
      periods++;
      monthOffset++;

      nextPeriodDate = _monthlyAnniversary(startDate, monthOffset);
    }

    return periods;
  }

  /// Calcula un aniversario mensual desde la fecha original.
  ///
  /// Si el día original no existe en el mes de destino,
  /// utiliza el último día disponible de ese mes.
  DateTime _monthlyAnniversary(DateTime startDate, int monthsToAdd) {
    // Obtiene el mes de destino.
    final targetMonth = DateTime(
      startDate.year,
      startDate.month + monthsToAdd,
      1,
    );

    // Determina el último día del mes de destino.
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;

    // Conserva el día original o utiliza el último día disponible.
    final day = startDate.day > lastDay ? lastDay : startDate.day;

    return DateTime(targetMonth.year, targetMonth.month, day);
  }

  /// Distribuye un pago ordinario entre intereses pendientes
  /// y capital.
  ///
  /// Primero cubre los intereses y luego reduce el capital.
  Map<String, double> _distributePayment({
    required double paymentAmount,
    required double pendingInterest,
    required double capitalBalance,
  }) {
    // El pago no puede destinar a intereses más de lo pendiente.
    final interestPayment = paymentAmount >= pendingInterest
        ? pendingInterest
        : paymentAmount;

    // Calcula el importe disponible después de pagar intereses.
    final remainingPayment = paymentAmount - interestPayment;

    // El abono a capital no puede superar el capital pendiente.
    final principalPayment = remainingPayment >= capitalBalance
        ? capitalBalance
        : remainingPayment;

    // Redondea los importes registrados a dos decimales.
    final roundedInterest = _roundCurrency(interestPayment);
    final roundedPrincipal = _roundCurrency(principalPayment);

    return {
      'interesesPagados': roundedInterest,
      'abonoCapital': roundedPrincipal,
    };
  }

  // ---------------------------------------------------------------------------
  // UTILIDADES
  // ---------------------------------------------------------------------------

  /// Redondea un importe monetario a dos decimales.
  double _roundCurrency(double amount) {
    return double.parse(amount.toStringAsFixed(2));
  }

  /// Convierte una fecha ISO en una fecha sin componente de hora.
  DateTime _parseDateOnly(String date) {
    final parsedDate = DateTime.parse(date);

    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
  }

  /// Convierte una fecha al formato ISO YYYY-MM-DD.
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
