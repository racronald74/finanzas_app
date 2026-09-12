import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/obligation_provider.dart';
import '../../../shared/helpers/currency_formatter.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../data/models/obligation_model.dart';
import '../../../data/services/obligation_service.dart';
import 'add_obligation_screen.dart';
import '../../../providers/income_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../shared/widgets/app_background.dart';

/// Pantalla principal del módulo Obligaciones.
///
/// Permite:
/// - Visualizar el total de obligaciones pendientes.
/// - Consultar las obligaciones registradas.
/// - Filtrar obligaciones fijas y variables.
/// - Consultar el estado de cada obligación.
/// - Acceder posteriormente al detalle de una obligación.
/// - Registrar una nueva obligación.
class ObligationsScreen extends StatefulWidget {
  /// Acción para regresar a la pantalla Más.
  final VoidCallback? onBackPressed;

  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  const ObligationsScreen({
    super.key,
    this.onBackPressed,
    this.onAvatarPressed,
  });

  @override
  State<ObligationsScreen> createState() => _ObligationsScreenState();
}

class _ObligationsScreenState extends State<ObligationsScreen> {
  /// Filtro seleccionado actualmente.
  ///
  /// Valores posibles:
  /// - Todas
  /// - Fijas
  /// - Variables
  String _filtroSeleccionado = 'Todas';

  /// Obtiene las obligaciones correspondientes al período actual.
  ///
  /// Las obligaciones históricas permanecen almacenadas,
  /// pero solo participan en los filtros del período actual.
  List<ObligationModel> _currentPeriodObligations(
    List<ObligationModel> obligations,
  ) {
    final now = DateTime.now();

    return obligations.where((obligation) {
      final fecha = DateTime.tryParse(obligation.fechaVencimiento);

      if (fecha == null) return false;

      return fecha.year == now.year && fecha.month == now.month;
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    /// Carga las obligaciones después de construir
    /// la pantalla para poder acceder al Provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadObligations();
    });
  }

  /// Carga las obligaciones del usuario autenticado.
  Future<void> _loadObligations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final obligationProvider = Provider.of<ObligationProvider>(
      context,
      listen: false,
    );

    final usuario = authProvider.currentUser;

    if (usuario == null) return;

    await obligationProvider.loadObligations(usuario.idUsuario!);
  }

  /// Filtra las obligaciones según el filtro seleccionado.
  ///
  /// 'Todas' muestra todo el historial.
  /// Los demás filtros trabajan únicamente con
  /// las obligaciones del período actual.
  List<ObligationModel> _filterObligations(List<ObligationModel> obligations) {
    if (_filtroSeleccionado == 'Todas') {
      return obligations;
    }

    final currentPeriod = _currentPeriodObligations(obligations);

    switch (_filtroSeleccionado) {
      case 'Fijas':
        return currentPeriod
            .where((obligation) => obligation.esRecurrente)
            .toList();

      case 'Variables':
        return currentPeriod
            .where((obligation) => !obligation.esRecurrente)
            .toList();

      case 'Pagadas':
        return currentPeriod
            .where(
              (obligation) =>
                  obligation.estado == ObligationService.estadoPagada,
            )
            .toList();

      default:
        return currentPeriod;
    }
  }

  /// Construye un botón de filtro.
  Widget _buildFilterButton(String text) {
    final bool selected = _filtroSeleccionado == text;

    return Expanded(
      child: SizedBox(
        height: 38,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _filtroSeleccionado = text;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: selected ? AppColors.primary : Colors.white,
            foregroundColor: selected ? Colors.white : Colors.grey.shade700,
            elevation: 0,
            side: BorderSide(
              color: selected ? AppColors.primary : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye la tarjeta superior de resumen.
  ///
  /// El icono permanece siempre a la izquierda.
  /// El contenido de texto se adapta al espacio disponible
  /// para evitar desbordamientos en diferentes dispositivos.
  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        // La tarjeta no tiene una altura fija.
        // Su contenido determina la altura necesaria.
        constraints: const BoxConstraints(minHeight: 74),

        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFD5E1ED)),
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ==================================================
            // Icono.
            //
            // Se mantiene siempre a la izquierda de la tarjeta.
            // ==================================================
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),

            const SizedBox(width: 8),

            // ==================================================
            // Contenido de la tarjeta.
            //
            // Expanded permite que el texto utilice únicamente
            // el espacio disponible después del icono.
            // ==================================================
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de la tarjeta.
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),

                  const SizedBox(height: 2),

                  // Valor monetario.
                  //
                  // FittedBox reduce el tamaño visual si el monto
                  // no cabe en el ancho disponible.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: valueColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la tarjeta individual de una obligación.
  ///
  /// La tarjeta muestra:
  /// - Icono de la obligación.
  /// - Nombre.
  /// - Fecha de vencimiento.
  /// - Tipo y frecuencia.
  /// - Monto.
  /// - Estado Pendiente/Pagada.
  /// - Acción para consultar el detalle.
  Widget _buildObligationCard(ObligationModel obligation) {
    final bool pagada = obligation.estado == ObligationService.estadoPagada;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          // Icono de la obligación.
          _buildObligationIcon(obligation),

          const SizedBox(width: 9),

          // Información principal.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obligation.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  'Vence: ${_formatDate(obligation.fechaVencimiento)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 0),
                Text(
                  obligation.esRecurrente
                      ? 'Fija - ${obligation.frecuencia}'
                      : 'Única',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Monto y estado.
          SizedBox(
            width: 82,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(obligation.monto),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                GestureDetector(
                  onTap: pagada
                      ? null
                      : () async {
                          final provider = Provider.of<ObligationProvider>(
                            context,
                            listen: false,
                          );

                          final confirmed = await _confirmMarkAsPaid(
                            obligation,
                          );

                          if (!confirmed) return;

                          final success = await provider.markAsPaid(obligation);

                          if (!mounted) return;

                          if (!success) {
                            // Muestra el error si no fue posible registrar el pago.
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.errorMessage.isEmpty
                                      ? 'No fue posible marcar la obligación como pagada'
                                      : provider.errorMessage,
                                ),
                              ),
                            );

                            return;
                          }

                          // Obtiene los Providers necesarios para recalcular
                          // el presupuesto después de generar el gasto.
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );

                          final incomeProvider = Provider.of<IncomeProvider>(
                            context,
                            listen: false,
                          );

                          final expenseProvider = Provider.of<ExpenseProvider>(
                            context,
                            listen: false,
                          );

                          final budgetProvider = Provider.of<BudgetProvider>(
                            context,
                            listen: false,
                          );

                          final usuario = authProvider.currentUser;

                          if (usuario == null) return;

                          // Recarga los ingresos y gastos para incluir
                          // inmediatamente el gasto generado por la obligación.
                          await incomeProvider.loadIncomeData(
                            usuario.idUsuario!,
                          );
                          await expenseProvider.loadExpenses(
                            usuario.idUsuario!,
                          );

                          if (!mounted) return;

                          // Define el inicio del período financiero actual.
                          final now = DateTime.now();
                          final currentPeriodStart = DateTime(
                            now.year,
                            now.month,
                            1,
                          );

                          // Recalcula el saldo inicial del período.
                          final initialBalance = await budgetProvider
                              .calculateInitialBalance(
                                idUsuario: usuario.idUsuario!,
                                currentPeriodStart: currentPeriodStart,
                                fixedIncome: usuario.ingresoFijoMensual,
                                registrationDate: DateTime.parse(
                                  usuario.fechaRegistro,
                                ),
                              );

                          if (!mounted) return;

                          // Actualiza el resumen del presupuesto con los datos actuales.
                          budgetProvider.updateBudget(
                            initialBalance: initialBalance,
                            fixedIncome: usuario.ingresoFijoMensual,
                            additionalIncome:
                                incomeProvider.currentMonthAdditionalIncome,
                            totalExpenses: expenseProvider.totalExpenses,
                            totalSavings: 0,
                          );
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: pagada
                          ? const Color(0xFFD7F3E5)
                          : const Color(0xFFFFCACA),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      pagada ? 'Pagada' : 'Pendiente',
                      style: TextStyle(
                        fontSize: 11,
                        color: pagada
                            ? const Color(0xFF15965A)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Abre el detalle de la obligación.
          if (!pagada)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddObligationScreen(initialObligation: obligation),
                  ),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              icon: const Icon(
                Icons.remove_red_eye_outlined,
                size: 25,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }

  /// Icono visual asociado a la obligación.
  ///
  /// Por ahora utiliza diferentes iconos según
  /// el nombre para acercarnos al prototipo.
  Widget _buildObligationIcon(ObligationModel obligation) {
    IconData icon = Icons.receipt_long_outlined;
    Color background = const Color(0xFFE8E8E8);
    Color color = Colors.grey;

    final nombre = obligation.nombre.toLowerCase();

    if (nombre.contains('arriendo')) {
      icon = Icons.home_outlined;
      background = const Color(0xFFD7ECFF);
      color = const Color(0xFF2196F3);
    } else if (nombre.contains('luz')) {
      icon = Icons.lightbulb_outline;
      background = const Color(0xFFFFEFCB);
      color = const Color(0xFFFFB52E);
    } else if (nombre.contains('agua')) {
      icon = Icons.water_drop_outlined;
      background = const Color(0xFFD7ECFF);
      color = const Color(0xFF2196F3);
    } else if (nombre.contains('colegio')) {
      icon = Icons.school_outlined;
      background = const Color(0xFFD7F3E5);
      color = const Color(0xFF16B86A);
    } else if (nombre.contains('tarjeta')) {
      icon = Icons.credit_card_outlined;
      background = const Color(0xFFE9D9FF);
      color = const Color(0xFF8B3DFF);
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: color),
    );
  }

  /// Formatea una fecha ISO para mostrarla en pantalla.
  String _formatDate(String fecha) {
    final date = DateTime.tryParse(fecha);

    if (date == null) {
      return fecha;
    }

    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final obligationProvider = Provider.of<ObligationProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);

    final obligations = _filterObligations(obligationProvider.obligations);

    return Scaffold(
      body: Column(
        children: [
          /// Encabezado reutilizado de la aplicación.
          AppHeader(
            title: 'Obligaciones',
            showAvatar: true,
            showNotification: true,
            onAvatarPressed: widget.onAvatarPressed,
          ),

          // Contenido principal.
          Expanded(
            child: AppBackground(
              child: Column(
                children: [
                  // Contenido fijo: resumen y filtros.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        /// Resumen superior.
                        Row(
                          children: [
                            _buildSummaryCard(
                              icon: Icons.account_balance_outlined,
                              iconColor: const Color(0xFF2196F3),
                              iconBackground: const Color(0xFFD7ECFF),
                              title: 'Total comprometido',
                              value: CurrencyFormatter.format(
                                obligationProvider.totalCommitted,
                              ),
                              valueColor: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            _buildSummaryCard(
                              icon: Icons.calendar_month_outlined,
                              iconColor: const Color(0xFFFFB52E),
                              iconBackground: const Color(0xFFFFEDC9),
                              title: 'Disponible proyectado',
                              value: CurrencyFormatter.format(
                                budgetProvider.summary.availableBudget -
                                    obligationProvider.totalCommitted,
                              ),
                              valueColor: const Color(0xFF16B86A),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        /// Filtros.
                        Row(
                          children: [
                            _buildFilterButton('Todas'),
                            const SizedBox(width: 6),
                            _buildFilterButton('Fijas'),
                            const SizedBox(width: 6),
                            _buildFilterButton('Variables'),
                            const SizedBox(width: 6),
                            _buildFilterButton('Pagadas'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Únicamente el historial tiene desplazamiento.
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: obligations.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 28,
                              ),
                              child: Column(
                                children: [
                                  // Icono representativo del estado vacío.
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD7F3E5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 32,
                                      color: Color(0xFF16B86A),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Mensaje principal.
                                  const Text(
                                    'No tienes obligaciones registradas',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF303030),
                                    ),
                                  ),

                                  const SizedBox(height: 7),

                                  // Explicación del estado vacío.
                                  const Text(
                                    'Registra tus obligaciones mensuales para '
                                    'llevar un mejor control de tus pagos.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: obligations
                                  .map(_buildObligationCard)
                                  .toList(),
                            ),
                    ),
                  ),
                  // Botón fijo para registrar una nueva obligación.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddObligationScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Registrar nueva obligación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<bool> _confirmMarkAsPaid(ObligationModel obligation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar pago'),
          content: Text(
            '¿Deseas marcar la obligación "${obligation.nombre}" como pagada?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Marcar como pagada'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }
}
