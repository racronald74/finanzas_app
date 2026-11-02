/// Modelo que representa una deuda del usuario.
///
/// Transporta información entre SQLite, Repository,
/// Service, Provider y las pantallas de Deudas.
class DebtModel {
  /// Identificador de la deuda.
  final int? idDeuda;

  /// Nombre o persona/entidad a quien se debe.
  final String acreedor;

  /// Monto total de la deuda.
  final double montoTotal;

  /// Saldo total pendiente, incluyendo intereses pendientes.
  final double saldoPendiente;

  /// Capital que todavía debe el usuario.
  final double saldoCapital;

  /// Capital existente al inicio del período mensual actual.
  final double capitalInicioPeriodo;

  /// Intereses generados que todavía están pendientes de pago.
  final double interesesPendientes;

  /// Fecha hasta la que se calcularon los intereses.
  /// Se almacena en formato ISO.
  final String? fechaUltimoCalculoIntereses;

  /// Tasa de interés efectiva anual, expresada en porcentaje.
  final double tasaInteresEA;

  /// Cuota mensual calculada mediante amortización francesa.
  final double? cuotaMensual;

  /// Plazo de la deuda en meses.
  final int? plazo;

  /// Fecha de inicio en formato ISO.
  final String fechaInicio;

  /// Indica si tiene recordatorio activo.
  final bool recordatorio;

  /// Estado de la deuda: Activa o Pagada.
  final String estado;

  /// Identificador del usuario propietario.
  final int idUsuario;

  /// Fecha de creación del registro.
  final String fechaRegistro;

  /// Constructor del modelo.
  ///
  /// saldoCapital toma saldoPendiente como valor inicial
  /// cuando no se proporciona, para mantener compatibilidad.
  const DebtModel({
    this.idDeuda,
    required this.acreedor,
    required this.montoTotal,
    required this.saldoPendiente,
    double? saldoCapital,
    this.interesesPendientes = 0,
    this.fechaUltimoCalculoIntereses,
    double tasaInteresEA = 0,
    @Deprecated('Utilizar tasaInteresEA') double? tasaInteres,
    this.cuotaMensual,
    this.plazo,
    required this.fechaInicio,
    required this.recordatorio,
    required this.estado,
    required this.idUsuario,
    required this.fechaRegistro,
    double? capitalInicioPeriodo,
  }) : saldoCapital = saldoCapital ?? saldoPendiente,
       capitalInicioPeriodo =
           capitalInicioPeriodo ?? saldoCapital ?? saldoPendiente,
       tasaInteresEA = tasaInteres ?? tasaInteresEA;

  /// Getter temporal para mantener compatibilidad con código anterior.
  @Deprecated('Utilizar tasaInteresEA')
  double get tasaInteres => tasaInteresEA;

  /// Convierte el objeto en un Map para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id_deuda': idDeuda,
      'acreedor': acreedor,
      'monto_total': montoTotal,
      'saldo_pendiente': saldoPendiente,
      'saldo_capital': saldoCapital,
      'tasa_interes_ea': tasaInteresEA,
      'capital_inicio_periodo': capitalInicioPeriodo,

      // Se conserva temporalmente el campo anterior.
      'tasa_interes': tasaInteresEA,
      'intereses_pendientes': interesesPendientes,
      'fecha_ultimo_calculo_intereses': fechaUltimoCalculoIntereses,

      'cuota_mensual': cuotaMensual,
      'plazo': plazo,
      'fecha_inicio': fechaInicio,
      'recordatorio': recordatorio ? 1 : 0,
      'estado': estado,
      'id_usuario': idUsuario,
      'fecha_registro': fechaRegistro,
    };
  }

  /// Crea un DebtModel a partir de un registro de SQLite.
  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      idDeuda: map['id_deuda'],
      acreedor: map['acreedor'],
      montoTotal: (map['monto_total'] as num).toDouble(),
      saldoPendiente: (map['saldo_pendiente'] as num).toDouble(),
      saldoCapital: (map['saldo_capital'] as num?)?.toDouble(),
      tasaInteresEA:
          (map['tasa_interes_ea'] as num?)?.toDouble() ??
          (map['tasa_interes'] as num?)?.toDouble() ??
          0,
      capitalInicioPeriodo: (map['capital_inicio_periodo'] as num?)?.toDouble(),
      cuotaMensual: (map['cuota_mensual'] as num?)?.toDouble(),
      plazo: map['plazo'],
      fechaInicio: map['fecha_inicio'],
      recordatorio: map['recordatorio'] == 1,
      estado: map['estado'],
      idUsuario: map['id_usuario'],
      fechaRegistro: map['fecha_registro'],
      interesesPendientes:
          (map['intereses_pendientes'] as num?)?.toDouble() ?? 0,
      fechaUltimoCalculoIntereses:
          map['fecha_ultimo_calculo_intereses'] as String?,
    );
  }

  /// Crea una copia modificando únicamente
  /// los campos enviados como parámetro.
  DebtModel copyWith({
    int? idDeuda,
    String? acreedor,
    double? montoTotal,
    double? saldoPendiente,
    double? saldoCapital,
    double? tasaInteresEA,
    double? interesesPendientes,
    String? fechaUltimoCalculoIntereses,
    double? capitalInicioPeriodo,
    @Deprecated('Utilizar tasaInteresEA') double? tasaInteres,
    double? cuotaMensual,
    int? plazo,
    String? fechaInicio,
    bool? recordatorio,
    String? estado,
    int? idUsuario,
    String? fechaRegistro,
  }) {
    return DebtModel(
      idDeuda: idDeuda ?? this.idDeuda,
      acreedor: acreedor ?? this.acreedor,
      montoTotal: montoTotal ?? this.montoTotal,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      saldoCapital: saldoCapital ?? this.saldoCapital,
      tasaInteresEA: tasaInteres ?? tasaInteresEA ?? this.tasaInteresEA,
      interesesPendientes: interesesPendientes ?? this.interesesPendientes,
      fechaUltimoCalculoIntereses:
          fechaUltimoCalculoIntereses ?? this.fechaUltimoCalculoIntereses,
      capitalInicioPeriodo: capitalInicioPeriodo ?? this.capitalInicioPeriodo,
      cuotaMensual: cuotaMensual ?? this.cuotaMensual,
      plazo: plazo ?? this.plazo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      recordatorio: recordatorio ?? this.recordatorio,
      estado: estado ?? this.estado,
      idUsuario: idUsuario ?? this.idUsuario,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}
