import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:finanzas_app/data/database/database_helper.dart';
import 'package:finanzas_app/data/services/debt_service.dart';
import 'package:finanzas_app/data/models/debt_model.dart';
import 'package:finanzas_app/data/models/debt_payment_model.dart';
import 'package:finanzas_app/data/services/debt_amortization_service.dart';

void main() {
  // Inicializa SQLite para ejecutarse en el entorno de pruebas.
  sqfliteFfiInit();

  // Configura el motor SQLite para las pruebas.
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper databaseHelper;

  setUp(() async {
    // Crea una base de datos temporal en memoria.
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );

    // Prepara el helper con la base de datos temporal.
    databaseHelper = DatabaseHelper.forTesting(database);

    // Crea las tablas y categorías necesarias.
    await databaseHelper.initializeForTesting();
  });

  tearDown(() async {
    // Cierra la base de datos al terminar cada prueba.
    await databaseHelper.close();
  });

  // ---------------------------------------------------------------------------
  // MÉTODOS AUXILIARES PARA LAS PRUEBAS
  // ---------------------------------------------------------------------------

  /// Registra una deuda estándar para reutilizarla en las pruebas.
  Future<int> createTestDebt(DebtService service) async {
    final debt = DebtModel(
      acreedor: 'Banco de prueba',
      montoTotal: 1000000,
      saldoPendiente: 1000000,
      tasaInteresEA: 24,
      plazo: 12,
      fechaInicio: '2026-11-02',
      recordatorio: false,
      estado: 'Activa',
      idUsuario: 1,
      fechaRegistro: '2026-11-02',
    );

    return service.createDebt(debt);
  }

  /// Construye un pago estándar para las pruebas.
  DebtPaymentModel createTestPayment({
    required int debtId,
    required double amount,
    required String date,
  }) {
    return DebtPaymentModel(
      monto: amount,
      fecha: date,
      idDeuda: debtId,
      fechaRegistro: date,
    );
  }

  group('DebtService - pruebas de integración', () {
    test('debe inicializar correctamente la base de datos', () async {
      // Verifica que exista la tabla de deudas.
      final db = await databaseHelper.database;

      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'deuda'",
      );

      expect(result, isNotEmpty);
    });

    test('debe utilizar la base de datos temporal desde DebtService', () async {
      // Arrange: crea el servicio de deudas.
      final service = DebtService();

      // Act: consulta las deudas de un usuario de prueba.
      final debts = await service.getDebtsByUser(1);

      // Assert: la consulta debe ejecutarse correctamente.
      expect(debts, isEmpty);
    });

    test(
      'debe registrar una deuda calculando sus condiciones financieras',
      () async {
        // Arrange: prepara el servicio y una deuda de prueba.
        final service = DebtService();

        final debt = DebtModel(
          acreedor: 'Banco de prueba',
          montoTotal: 1000000,
          saldoPendiente: 1000000,
          tasaInteresEA: 24,
          plazo: 12,
          fechaInicio: '2026-11-02',
          recordatorio: false,
          estado: 'Activa',
          idUsuario: 1,
          fechaRegistro: '2026-11-02',
        );

        // Act: registra la deuda.
        final debtId = await service.createDebt(debt);

        // Recupera la deuda guardada en SQLite.
        final savedDebt = await service.getDebtById(debtId);

        // Assert: verifica que se haya registrado correctamente.
        expect(savedDebt, isNotNull);
        expect(savedDebt!.montoTotal, 1000000);
        expect(savedDebt.saldoCapital, 1000000);
        expect(savedDebt.saldoPendiente, 1000000);
        expect(savedDebt.capitalInicioPeriodo, 1000000);
        expect(savedDebt.tasaInteresEA, 24);

        // Verifica que se haya calculado una cuota mensual.
        expect(savedDebt.cuotaMensual, isNotNull);
        expect(savedDebt.cuotaMensual!, greaterThan(0));
      },
    );

    test('debe rechazar una deuda con monto igual a cero', () async {
      // Arrange: prepara una deuda con un monto no permitido.
      final service = DebtService();

      final debt = DebtModel(
        acreedor: 'Banco de prueba',
        montoTotal: 0,
        saldoPendiente: 0,
        tasaInteresEA: 24,
        plazo: 12,
        fechaInicio: '2026-11-02',
        recordatorio: false,
        estado: 'Activa',
        idUsuario: 1,
        fechaRegistro: '2026-11-02',
      );

      // Act + Assert: verifica que se rechace el registro.
      expect(() => service.createDebt(debt), throwsA(isA<Exception>()));
    });

    test('debe rechazar una deuda con tasa EA negativa', () async {
      // Arrange: prepara una deuda con una tasa no permitida.
      final service = DebtService();

      final debt = DebtModel(
        acreedor: 'Banco de prueba',
        montoTotal: 1000000,
        saldoPendiente: 1000000,
        tasaInteresEA: -5,
        plazo: 12,
        fechaInicio: '2026-11-02',
        recordatorio: false,
        estado: 'Activa',
        idUsuario: 1,
        fechaRegistro: '2026-11-02',
      );

      // Act + Assert: verifica que se rechace el registro.
      expect(() => service.createDebt(debt), throwsA(isA<Exception>()));
    });

    test('debe rechazar una deuda con plazo igual a cero', () async {
      // Arrange: prepara una deuda con un plazo no permitido.
      final service = DebtService();

      final debt = DebtModel(
        acreedor: 'Banco de prueba',
        montoTotal: 1000000,
        saldoPendiente: 1000000,
        tasaInteresEA: 24,
        plazo: 0,
        fechaInicio: '2026-11-02',
        recordatorio: false,
        estado: 'Activa',
        idUsuario: 1,
        fechaRegistro: '2026-11-02',
      );

      // Act + Assert: verifica que se rechace el registro.
      expect(() => service.createDebt(debt), throwsA(isA<Exception>()));
    });

    test('debe rechazar una deuda con acreedor vacío', () async {
      // Arrange: prepara una deuda sin nombre de acreedor.
      final service = DebtService();

      final debt = DebtModel(
        acreedor: '',
        montoTotal: 1000000,
        saldoPendiente: 1000000,
        tasaInteresEA: 24,
        plazo: 12,
        fechaInicio: '2026-11-02',
        recordatorio: false,
        estado: 'Activa',
        idUsuario: 1,
        fechaRegistro: '2026-11-02',
      );

      // Act + Assert: verifica que se rechace el registro.
      expect(() => service.createDebt(debt), throwsA(isA<Exception>()));
    });

    // -------------------------------------------------------------------------
    // PRUEBAS DEL REGISTRO DE PAGOS
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // PRUEBAS DE VISTA PREVIA DE PAGOS ORDINARIOS
    // -------------------------------------------------------------------------

    test(
      'debe calcular la distribución del pago sin modificar la deuda',
      () async {
        // Arrange: registra una deuda de prueba.
        final service = DebtService();
        final debtId = await createTestDebt(service);

        // Consulta el estado original de la deuda.
        final originalDebt = await service.getDebtById(debtId);

        final payment = createTestPayment(
          debtId: debtId,
          amount: 100000,
          date: '2026-12-02',
        );

        // Act: calcula la vista previa sin registrar el pago.
        final preview = await service.previewPayment(payment);

        // Consulta nuevamente la deuda.
        final unchangedDebt = await service.getDebtById(debtId);
        final payments = await service.getPaymentsByDebt(debtId);

        // Calcula los intereses esperados del primer período.
        final amortizationService = DebtAmortizationService();
        final monthlyRate = amortizationService.calculateMonthlyRate(24);

        final expectedInterest = double.parse(
          (1000000 * monthlyRate).toStringAsFixed(2),
        );

        final expectedPrincipal = double.parse(
          (100000 - expectedInterest).toStringAsFixed(2),
        );

        // Verifica el importe y la distribución del pago.
        expect(preview.montoPago, 100000);
        expect(preview.interesesPagados, expectedInterest);
        expect(preview.abonoCapital, expectedPrincipal);

        // Verifica el saldo restante.
        expect(
          preview.capitalRestante,
          closeTo(1000000 - expectedPrincipal, 0.01),
        );
        expect(preview.interesesRestantes, 0);

        // El pago es superior a la cuota mensual.
        expect(preview.pagoInferiorCuota, false);

        // La vista previa no debe modificar la deuda.
        expect(unchangedDebt!.saldoCapital, originalDebt!.saldoCapital);
        expect(unchangedDebt.saldoPendiente, originalDebt.saldoPendiente);
        expect(
          unchangedDebt.fechaUltimoCalculoIntereses,
          originalDebt.fechaUltimoCalculoIntereses,
        );

        // No debe registrar pagos ni gastos.
        expect(payments, isEmpty);

        final db = await databaseHelper.database;
        final expenses = await db.rawQuery(
          'SELECT * FROM gasto WHERE origen = ?',
          ['DEUDA'],
        );

        expect(expenses, isEmpty);
      },
    );

    test('debe identificar un pago inferior a la cuota mensual', () async {
      // Arrange: registra una deuda de prueba.
      final service = DebtService();
      final debtId = await createTestDebt(service);

      final payment = createTestPayment(
        debtId: debtId,
        amount: 5000,
        date: '2026-12-02',
      );

      // Act: calcula la vista previa de un pago parcial.
      final preview = await service.previewPayment(payment);

      // Assert: identifica que el pago es inferior a la cuota.
      expect(preview.pagoInferiorCuota, true);

      // El pago se destina primero a cubrir intereses.
      expect(preview.interesesPagados, 5000);
      expect(preview.abonoCapital, 0);

      // El capital permanece sin modificaciones.
      expect(preview.capitalRestante, 1000000);

      // Los intereses restantes deben ser positivos.
      expect(preview.interesesRestantes, greaterThan(0));
    });

    test(
      'debe aplicar primero los intereses y luego reducir el capital',
      () async {
        // Arrange: registra una deuda de prueba.
        final service = DebtService();
        final debtId = await createTestDebt(service);

        final payment = createTestPayment(
          debtId: debtId,
          amount: 100000,
          date: '2026-12-02',
        );

        // Act: registra el pago al finalizar el primer período.
        await service.registerPayment(payment);

        // Recupera la deuda y el historial actualizado.
        final updatedDebt = await service.getDebtById(debtId);
        final payments = await service.getPaymentsByDebt(debtId);

        // Assert: verifica la distribución del pago.
        expect(updatedDebt, isNotNull);
        expect(updatedDebt!.interesesPendientes, 0);
        expect(updatedDebt.saldoCapital, lessThan(1000000));

        expect(payments, hasLength(1));
        expect(payments.first.interesesPagados, greaterThan(0));
        expect(payments.first.abonoCapital, greaterThan(0));

        // El pago debe distribuirse completamente.
        expect(
          payments.first.interesesPagados + payments.first.abonoCapital,
          closeTo(100000, 0.01),
        );

        // Verifica la fecha del último cálculo de intereses.
        expect(updatedDebt.fechaUltimoCalculoIntereses, '2026-12-02');

        // Verifica que el gasto automático haya sido registrado.
        final db = await databaseHelper.database;

        final expenses = await db.rawQuery(
          'SELECT * FROM gasto WHERE origen = ?',
          ['DEUDA'],
        );

        expect(expenses, hasLength(1));
        expect((expenses.first['monto'] as num).toDouble(), 100000);
      },
    );

    test(
      'debe conservar el capital cuando el pago no cubre los intereses',
      () async {
        // Arrange: registra una deuda de prueba.
        final service = DebtService();
        final debtId = await createTestDebt(service);

        final payment = createTestPayment(
          debtId: debtId,
          amount: 5000,
          date: '2026-12-02',
        );

        // Act: registra un pago inferior a los intereses generados.
        await service.registerPayment(payment);

        final updatedDebt = await service.getDebtById(debtId);
        final payments = await service.getPaymentsByDebt(debtId);

        // Assert: el pago se destinó completamente a intereses.
        expect(updatedDebt, isNotNull);
        expect(updatedDebt!.saldoCapital, 1000000);
        expect(updatedDebt.interesesPendientes, greaterThan(0));

        expect(payments, hasLength(1));
        expect(payments.first.interesesPagados, 5000);
        expect(payments.first.abonoCapital, 0);

        // El saldo total incluye capital e intereses pendientes.
        expect(
          updatedDebt.saldoPendiente,
          closeTo(
            updatedDebt.saldoCapital + updatedDebt.interesesPendientes,
            0.01,
          ),
        );
      },
    );

    test(
      'debe generar intereses por todos los períodos mensuales vencidos',
      () async {
        // Arrange: registra una deuda de prueba.
        final service = DebtService();
        final debtId = await createTestDebt(service);

        final payment = createTestPayment(
          debtId: debtId,
          amount: 1000,
          date: '2027-02-02',
        );

        // Act: registra un pago después de tres períodos mensuales.
        await service.registerPayment(payment);

        final updatedDebt = await service.getDebtById(debtId);

        // Assert: el capital no se reduce porque el pago
        // se destina primero a los intereses pendientes.
        expect(updatedDebt, isNotNull);
        expect(updatedDebt!.saldoCapital, 1000000);

        // Se acumulan los intereses de los tres períodos.
        expect(updatedDebt.interesesPendientes, greaterThan(0));

        // La fecha debe corresponder al último período calculado.
        expect(updatedDebt.fechaUltimoCalculoIntereses, '2027-02-02');

        // Los intereses no se suman al capital.
        expect(
          updatedDebt.saldoPendiente,
          closeTo(1000000 + updatedDebt.interesesPendientes, 0.01),
        );
      },
    );

    test('debe rechazar pagos superiores al saldo actualizado', () async {
      // Arrange: registra una deuda de prueba.
      final service = DebtService();
      final debtId = await createTestDebt(service);

      final payment = createTestPayment(
        debtId: debtId,
        amount: 2000000,
        date: '2026-12-02',
      );

      // Act + Assert: el pago supera el capital y los intereses.
      expect(() => service.registerPayment(payment), throwsA(isA<Exception>()));

      // La transacción debe revertir los cambios.
      final unchangedDebt = await service.getDebtById(debtId);
      final payments = await service.getPaymentsByDebt(debtId);

      expect(unchangedDebt, isNotNull);
      expect(unchangedDebt!.saldoCapital, 1000000);
      expect(unchangedDebt.interesesPendientes, 0);
      expect(unchangedDebt.saldoPendiente, 1000000);
      expect(unchangedDebt.fechaUltimoCalculoIntereses, isNull);

      // No debe quedar registrado ningún pago.
      expect(payments, isEmpty);

      // Tampoco debe quedar registrado un gasto.
      final db = await databaseHelper.database;

      final expenses = await db.rawQuery(
        'SELECT * FROM gasto WHERE origen = ?',
        ['DEUDA'],
      );

      expect(expenses, isEmpty);
    });

    test(
      'debe actualizar correctamente el saldo y el historial de pagos',
      () async {
        // Arrange: registra una deuda de prueba.
        final service = DebtService();
        final debtId = await createTestDebt(service);

        // Act: realiza dos pagos en fechas diferentes.
        await service.registerPayment(
          createTestPayment(debtId: debtId, amount: 100000, date: '2026-12-02'),
        );

        await service.registerPayment(
          createTestPayment(debtId: debtId, amount: 50000, date: '2026-12-15'),
        );

        final updatedDebt = await service.getDebtById(debtId);
        final payments = await service.getPaymentsByDebt(debtId);

        // Assert: ambos pagos deben estar registrados.
        expect(payments, hasLength(2));

        // El capital debe disminuir con los pagos realizados.
        expect(updatedDebt, isNotNull);
        expect(updatedDebt!.saldoCapital, lessThan(1000000));

        // No se generan nuevos intereses si no ha terminado
        // otro período mensual.
        expect(updatedDebt.fechaUltimoCalculoIntereses, '2026-12-02');

        // El saldo debe corresponder a capital más intereses.
        expect(
          updatedDebt.saldoPendiente,
          closeTo(
            updatedDebt.saldoCapital + updatedDebt.interesesPendientes,
            0.01,
          ),
        );
      },
    );

    // -------------------------------------------------------------------------
    // PRUEBAS DE ABONOS EXTRAORDINARIOS
    // -------------------------------------------------------------------------

    test('debe reducir el plazo conservando la cuota mensual', () async {
      // Arrange: registra una deuda de prueba.
      final service = DebtService();
      final debtId = await createTestDebt(service);

      // Recupera las condiciones originales.
      final originalDebt = await service.getDebtById(debtId);

      // Construye un abono extraordinario para reducir el plazo.
      final payment = DebtPaymentModel(
        monto: 100000,
        fecha: '2026-11-02',
        idDeuda: debtId,
        fechaRegistro: '2026-11-02',
        tipoPago: 'EXTRAORDINARIO',
        opcionAbono: 'REDUCIR_PLAZO',
      );

      // Act: registra el abono extraordinario.
      await service.registerExtraordinaryPayment(payment);

      final updatedDebt = await service.getDebtById(debtId);
      final payments = await service.getPaymentsByDebt(debtId);

      // Assert: el capital disminuye en el importe abonado.
      expect(updatedDebt, isNotNull);
      expect(updatedDebt!.saldoCapital, 900000);

      // Los intereses pendientes no deben modificarse.
      expect(updatedDebt.interesesPendientes, 0);

      // La cuota mensual debe conservar su valor original.
      expect(
        updatedDebt.cuotaMensual,
        closeTo(originalDebt!.cuotaMensual!, 0.01),
      );

      // El nuevo plazo debe ser inferior al original.
      expect(updatedDebt.plazo, lessThan(originalDebt.plazo!));

      // Verifica el registro del abono extraordinario.
      expect(payments, hasLength(1));
      expect(payments.first.tipoPago, 'EXTRAORDINARIO');
      expect(payments.first.opcionAbono, 'REDUCIR_PLAZO');
      expect(payments.first.abonoCapital, 100000);
      expect(payments.first.interesesPagados, 0);

      // Verifica que se haya generado el gasto.
      final db = await databaseHelper.database;
      final expenses = await db.rawQuery(
        'SELECT * FROM gasto WHERE origen = ?',
        ['DEUDA'],
      );

      expect(expenses, hasLength(1));
      expect((expenses.first['monto'] as num).toDouble(), 100000);
    });

    test('debe reducir la cuota conservando el plazo restante', () async {
      // Arrange: registra una deuda de prueba.
      final service = DebtService();
      final debtId = await createTestDebt(service);

      final originalDebt = await service.getDebtById(debtId);

      // Construye un abono extraordinario para reducir la cuota.
      final payment = DebtPaymentModel(
        monto: 100000,
        fecha: '2026-11-02',
        idDeuda: debtId,
        fechaRegistro: '2026-11-02',
        tipoPago: 'EXTRAORDINARIO',
        opcionAbono: 'REDUCIR_CUOTA',
      );

      // Act: registra el abono extraordinario.
      await service.registerExtraordinaryPayment(payment);

      final updatedDebt = await service.getDebtById(debtId);
      final payments = await service.getPaymentsByDebt(debtId);

      // Assert: el capital disminuye.
      expect(updatedDebt, isNotNull);
      expect(updatedDebt!.saldoCapital, 900000);

      // El plazo debe conservarse.
      expect(updatedDebt.plazo, originalDebt!.plazo);

      // La nueva cuota debe ser inferior a la original.
      expect(updatedDebt.cuotaMensual, lessThan(originalDebt.cuotaMensual!));

      // Los intereses pendientes permanecen iguales.
      expect(updatedDebt.interesesPendientes, 0);

      // Verifica la distribución del abono.
      expect(payments, hasLength(1));
      expect(payments.first.tipoPago, 'EXTRAORDINARIO');
      expect(payments.first.opcionAbono, 'REDUCIR_CUOTA');
      expect(payments.first.abonoCapital, 100000);
      expect(payments.first.interesesPagados, 0);
    });

    test('debe rechazar un abono extraordinario superior al capital', () async {
      // Arrange: registra una deuda de prueba.
      final service = DebtService();
      final debtId = await createTestDebt(service);

      final payment = DebtPaymentModel(
        monto: 1500000,
        fecha: '2026-11-02',
        idDeuda: debtId,
        fechaRegistro: '2026-11-02',
        tipoPago: 'EXTRAORDINARIO',
        opcionAbono: 'REDUCIR_PLAZO',
      );

      // Act + Assert: el abono supera el capital disponible.
      expect(
        () => service.registerExtraordinaryPayment(payment),
        throwsA(isA<Exception>()),
      );

      // Verifica que la deuda no haya sido modificada.
      final unchangedDebt = await service.getDebtById(debtId);
      final payments = await service.getPaymentsByDebt(debtId);

      expect(unchangedDebt, isNotNull);
      expect(unchangedDebt!.saldoCapital, 1000000);
      expect(unchangedDebt.saldoPendiente, 1000000);
      expect(payments, isEmpty);

      // Verifica que no se haya generado ningún gasto.
      final db = await databaseHelper.database;
      final expenses = await db.rawQuery(
        'SELECT * FROM gasto WHERE origen = ?',
        ['DEUDA'],
      );

      expect(expenses, isEmpty);
    });

    test('debe calcular los intereses del siguiente período sobre el capital '
        'reducido después de un abono extraordinario', () async {
      // Arrange: crear el servicio y registrar una deuda de prueba.
      final service = DebtService();
      final debtId = await createTestDebt(service);

      // Crear el servicio de amortización para calcular los intereses esperados.
      final amortizationService = DebtAmortizationService();
      final monthlyRate = amortizationService.calculateMonthlyRate(24);

      // Calcular los intereses del primer período sobre $1.000.000.
      final firstPeriodInterest = double.parse(
        (1000000 * monthlyRate).toStringAsFixed(2),
      );

      // Calcular los intereses del segundo período sobre $900.000.
      final secondPeriodInterest = double.parse(
        (900000 * monthlyRate).toStringAsFixed(2),
      );

      // Construir el abono extraordinario de $100.000.
      final extraordinaryPayment = DebtPaymentModel(
        monto: 100000,
        fecha: '2026-12-02',
        idDeuda: debtId,
        fechaRegistro: '2026-12-02',
        tipoPago: 'EXTRAORDINARIO',
        opcionAbono: 'REDUCIR_PLAZO',
      );

      // Act: registrar el abono extraordinario.
      await service.registerExtraordinaryPayment(extraordinaryPayment);

      // Consultar la deuda después del abono.
      var updatedDebt = await service.getDebtById(debtId);

      // Verificar que el capital de referencia se redujo a $900.000.
      expect(updatedDebt, isNotNull);
      expect(updatedDebt!.capitalInicioPeriodo, 900000);

      // Verificar los intereses generados durante el primer período.
      expect(updatedDebt.interesesPendientes, firstPeriodInterest);

      // Construir un pago ordinario de un centavo para el siguiente período.
      final ordinaryPayment = createTestPayment(
        debtId: debtId,
        amount: 0.01,
        date: '2027-01-02',
      );

      // Registrar el pago ordinario.
      await service.registerPayment(ordinaryPayment);

      // Consultar nuevamente la deuda.
      updatedDebt = await service.getDebtById(debtId);

      // Calcular los intereses pendientes esperados.
      final expectedPendingInterest = double.parse(
        (firstPeriodInterest + secondPeriodInterest - 0.01).toStringAsFixed(2),
      );

      // Verificar que el segundo período utilizó el capital reducido.
      expect(updatedDebt!.interesesPendientes, expectedPendingInterest);
    });
  });
}
