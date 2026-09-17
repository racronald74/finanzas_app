import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/data/models/income_model.dart';
import 'package:finanzas_app/data/services/income_service.dart';

void main() {
  group('IncomeService - validación de ingresos', () {
    test('debe rechazar un ingreso con monto igual a cero', () async {
      // Arrange: creamos un ingreso con un monto no permitido.
      final income = IncomeModel(
        descripcion: 'Ingreso de prueba',
        monto: 0,
        fecha: '2026-09-17',
        tipo: 'ADICIONAL',
        idCategoria: 1,
        idUsuario: 1,
      );

      final service = IncomeService();

      // Act + Assert: esperamos que la validación genere un ArgumentError.
      expect(() => service.createIncome(income), throwsA(isA<ArgumentError>()));
    });
  });
}
