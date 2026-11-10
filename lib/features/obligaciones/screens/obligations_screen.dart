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
class ObligationsScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  final VoidCallback? onAvatarPressed;
  final VoidCallback? onNotificationPressed;

  const ObligationsScreen({
    super.key,
    this.onBackPressed,
    this.onAvatarPressed,
    this.onNotificationPressed,
  });

  @override
  State<ObligationsScreen> createState() => _ObligationsScreenState();
}

class _ObligationsScreenState extends State<ObligationsScreen> {
  /// Filtro seleccionado actualmente.
  String _filtroSeleccionado = 'Todas';

  /// Detecta si está activo el tema de alto contraste.
  bool _isHighContrast(BuildContext context) {
    return Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);
  }

  /// Obtiene las obligaciones correspondientes al período actual.
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

    // Carga las obligaciones después de construir la pantalla.
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
    final bool highContrast = _isHighContrast(context);

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
            backgroundColor: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            foregroundColor: selected
                ? Colors.white
                : highContrast
                ? Colors.black
                : Colors.grey.shade700,
            elevation: 0,
            side: BorderSide(
              color: highContrast
                  ? Colors.black
                  : selected
                  ? AppColors.primary
                  : Colors.grey.shade300,
              width: highContrast ? 1.5 : 1,
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
  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    final bool highContrast = _isHighContrast(context);

    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: highContrast ? Colors.black : const Color(0xFFD5E1ED),
            width: highContrast ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icono de la tarjeta.
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: highContrast ? Colors.white : iconBackground,
                shape: BoxShape.circle,
                border: highContrast
                    ? Border.all(color: Colors.black, width: 1)
                    : null,
              ),
              child: Icon(
                icon,
                size: 20,
                color: highContrast
                    ? Theme.of(context).colorScheme.primary
                    : iconColor,
              ),
            ),

            const SizedBox(width: 8),

            // Contenido de la tarjeta.
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: highContrast ? Colors.black : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 2),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: highContrast ? Colors.black : valueColor,
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

  /// Construye la tarjeta de una obligación.
  Widget _buildObligationCard(ObligationModel obligation) {
    final bool pagada = obligation.estado == ObligationService.estadoPagada;

    final bool highContrast = _isHighContrast(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border(
          bottom: BorderSide(
            color: highContrast ? Colors.black : const Color(0xFFE0E0E0),
            width: highContrast ? 1.5 : 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono de la obligación.
          _buildObligationIcon(obligation),

          const SizedBox(width: 9),

          // Información principal.
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obligation.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: highContrast ? Colors.black : Colors.black87,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Vence: ${_formatDate(obligation.fechaVencimiento)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: highContrast ? Colors.black : Colors.grey,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  obligation.esRecurrente
                      ? 'Fija - ${obligation.frecuencia}'
                      : 'Única',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: highContrast ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Monto y estado de la obligación.
          SizedBox(
            width: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  CurrencyFormatter.format(obligation.monto),
                  maxLines: 2,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 5),

                // Permite cambiar el estado únicamente si está pendiente.
                GestureDetector(
                  onTap: pagada
                      ? null
                      : () async {
                          final provider = Provider.of<ObligationProvider>(
                            context,
                            listen: false,
                          );

                          // Solicita confirmación antes de registrar el pago.
                          final confirmed = await _confirmMarkAsPaid(
                            obligation,
                          );

                          if (!confirmed) return;

                          final success = await provider.markAsPaid(obligation);

                          if (!mounted) return;

                          if (!success) {
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

                          // Obtiene los proveedores necesarios.
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

                          // Recarga ingresos y gastos después del pago.
                          await incomeProvider.loadIncomeData(
                            usuario.idUsuario!,
                          );

                          await expenseProvider.loadExpenses(
                            usuario.idUsuario!,
                          );

                          if (!mounted) return;

                          // Calcula el inicio del período financiero actual.
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

                          // Actualiza el resumen del presupuesto.
                          budgetProvider.updateBudget(
                            initialBalance: initialBalance,
                            fixedIncome: usuario.ingresoFijoMensual,
                            additionalIncome:
                                incomeProvider.currentMonthAdditionalIncome,
                            totalExpenses: expenseProvider.totalExpenses,
                            totalSavings: 0,
                          );
                        },

                  // Etiqueta del estado.
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: highContrast
                          ? Colors.white
                          : pagada
                          ? const Color(0xFFD7F3E5)
                          : const Color(0xFFFFCACA),
                      borderRadius: BorderRadius.circular(5),
                      border: highContrast
                          ? Border.all(color: Colors.black, width: 1.2)
                          : null,
                    ),
                    child: Text(
                      pagada ? 'Pagada' : 'Pendiente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: highContrast
                            ? Colors.black
                            : pagada
                            ? const Color(0xFF15965A)
                            : const Color(0xFFE53935),
                        fontWeight: highContrast
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

          // Permite consultar o editar una obligación pendiente.
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
              icon: Icon(
                Icons.remove_red_eye_outlined,
                size: 25,
                color: highContrast ? Colors.black : Colors.black,
              ),
            ),
        ],
      ),
    );
  }

  /// Icono visual asociado a la obligación.
  Widget _buildObligationIcon(ObligationModel obligation) {
    final bool highContrast = _isHighContrast(context);

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
      decoration: BoxDecoration(
        color: highContrast ? Colors.white : background,
        shape: BoxShape.circle,
        border: highContrast
            ? Border.all(color: Colors.black, width: 1.5)
            : null,
      ),
      child: Icon(icon, size: 20, color: highContrast ? Colors.black : color),
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

    final bool highContrast = _isHighContrast(context);

    final obligations = _filterObligations(obligationProvider.obligations);

    return Scaffold(
      body: Column(
        children: [
          // Encabezado reutilizado de la aplicación.
          AppHeader(
            title: 'Obligaciones',
            showAvatar: true,
            showNotification: true,
            onAvatarPressed: widget.onAvatarPressed,
            onNotificationPressed: widget.onNotificationPressed,
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
                        // Resumen superior.
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

                        // Filtros.
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
                                    decoration: BoxDecoration(
                                      color: highContrast
                                          ? Colors.white
                                          : const Color(0xFFD7F3E5),
                                      shape: BoxShape.circle,
                                      border: highContrast
                                          ? Border.all(
                                              color: Colors.black,
                                              width: 1.5,
                                            )
                                          : null,
                                    ),
                                    child: Icon(
                                      Icons.calendar_month_outlined,
                                      size: 32,
                                      color: highContrast
                                          ? Colors.black
                                          : const Color(0xFF16B86A),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Mensaje principal.
                                  Text(
                                    'No tienes obligaciones registradas',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: highContrast
                                          ? Colors.black
                                          : const Color(0xFF303030),
                                    ),
                                  ),

                                  const SizedBox(height: 7),

                                  // Explicación del estado vacío.
                                  Text(
                                    'Registra tus obligaciones mensuales para '
                                    'llevar un mejor control de tus pagos.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.3,
                                      color: highContrast
                                          ? Colors.black
                                          : const Color(0xFF666666),
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: highContrast ? 0 : 2,
                          side: highContrast
                              ? const BorderSide(
                                  color: Colors.black,
                                  width: 1.5,
                                )
                              : BorderSide.none,
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

  /// Solicita confirmación antes de marcar una obligación como pagada.
  Future<bool> _confirmMarkAsPaid(ObligationModel obligation) async {
    final bool highContrast = _isHighContrast(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: highContrast
              ? RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          title: const Text(
            'Confirmar pago',
            style: TextStyle(color: Colors.black),
          ),
          content: Text(
            '¿Deseas marcar la obligación "${obligation.nombre}" como pagada?',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: highContrast
                      ? Colors.black
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Marcar como pagada'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }
}
