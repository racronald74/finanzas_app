/// Representa la distribución estimada de un pago ordinario.
///
/// Este modelo no registra movimientos ni modifica la deuda.
/// Solamente contiene los valores calculados para mostrarlos
/// antes de que el usuario confirme el pago.
class DebtPaymentPreviewModel {
  /// Importe total que el usuario desea pagar.
  final double montoPago;

  /// Intereses pendientes que se cubrirán con el pago.
  final double interesesPagados;

  /// Importe que se destinará a reducir el capital.
  final double abonoCapital;

  /// Intereses que quedarán pendientes después del pago.
  final double interesesRestantes;

  /// Capital que quedará pendiente después del pago.
  final double capitalRestante;

  /// Saldo total restante, incluyendo intereses pendientes.
  final double saldoRestante;

  /// Indica si el importe es inferior a la cuota mensual.
  final bool pagoInferiorCuota;

  const DebtPaymentPreviewModel({
    required this.montoPago,
    required this.interesesPagados,
    required this.abonoCapital,
    required this.interesesRestantes,
    required this.capitalRestante,
    required this.saldoRestante,
    required this.pagoInferiorCuota,
  });
}
