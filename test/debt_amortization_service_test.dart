import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_app/data/services/debt_amortization_service.dart';

void main() {
  // Instancia del servicio que vamos a probar.
  late DebtAmortizationService service;

  setUp(() {
    service = DebtAmortizationService();
  });

  group('Conversión de tasa de interés', () {
    test('Convierte correctamente una tasa del 24 % E.A.', () {
      final result = service.calculateMonthlyRate(24);

      // La tasa mensual esperada es aproximadamente 1.8088 %.
      expect(result, closeTo(0.018088, 0.000001));
    });

    test('Una tasa anual del 0 % produce tasa mensual del 0 %', () {
      final result = service.calculateMonthlyRate(0);

      expect(result, 0);
    });

    test('No permite tasas anuales negativas', () {
      expect(() => service.calculateMonthlyRate(-5), throwsArgumentError);
    });
  });

  group('Cálculo de cuota mensual', () {
    test('Calcula correctamente una cuota con intereses', () {
      final result = service.calculateMonthlyInstallment(
        principal: 1000000,
        monthlyRate: 0.018088,
        termInMonths: 12,
      );

      expect(result, closeTo(93400, 100));
    });

    test('Calcula la cuota cuando la tasa es cero', () {
      final result = service.calculateMonthlyInstallment(
        principal: 1200000,
        monthlyRate: 0,
        termInMonths: 12,
      );

      expect(result, 100000);
    });

    test('No permite capital igual a cero', () {
      expect(
        () => service.calculateMonthlyInstallment(
          principal: 0,
          monthlyRate: 0.01,
          termInMonths: 12,
        ),
        throwsArgumentError,
      );
    });

    test('No permite un plazo igual a cero', () {
      expect(
        () => service.calculateMonthlyInstallment(
          principal: 1000000,
          monthlyRate: 0.01,
          termInMonths: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Cálculos del período', () {
    test('Calcula los intereses sobre el capital pendiente', () {
      final result = service.calculatePeriodInterest(
        openingBalance: 1000000,
        monthlyRate: 0.02,
      );

      expect(result, 20000);
    });

    test('Calcula el capital incluido en la cuota', () {
      final result = service.calculatePeriodPrincipal(
        installment: 100000,
        interest: 20000,
      );

      expect(result, 80000);
    });

    test('Calcula el capital restante después del pago', () {
      final result = service.calculateRemainingCapital(
        openingBalance: 1000000,
        principalPayment: 80000,
      );

      expect(result, 920000);
    });

    test('No permite que el capital restante sea negativo', () {
      final result = service.calculateRemainingCapital(
        openingBalance: 50000,
        principalPayment: 80000,
      );

      expect(result, 0);
    });

    group('Abonos extraordinarios', () {
      test('Calcula el plazo reducido conservando la cuota mensual', () {
        final result = service.calculateReducedTerm(
          principal: 500000,
          monthlyRate: 0.018088,
          installment: 93400,
        );

        // El nuevo plazo debe ser menor a las 12 cuotas originales.
        expect(result, greaterThan(0));
        expect(result, lessThan(12));
      });

      test('Calcula la cuota reducida conservando el plazo', () {
        final result = service.calculateReducedInstallment(
          principal: 500000,
          monthlyRate: 0.018088,
          remainingTermInMonths: 12,
        );

        // La nueva cuota debe ser inferior a la cuota original.
        expect(result, lessThan(93400));
        expect(result, greaterThan(0));
      });

      test('No permite una cuota que no cubra los intereses', () {
        expect(
          () => service.calculateReducedTerm(
            principal: 500000,
            monthlyRate: 0.02,
            installment: 5000,
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
