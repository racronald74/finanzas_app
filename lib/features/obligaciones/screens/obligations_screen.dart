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
import '../../../providers/budget_provider.dart';

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
  List<ObligationModel> _filterObligations(List<ObligationModel> obligations) {
    switch (_filtroSeleccionado) {
      case 'Fijas':
        return obligations
            .where((obligation) => obligation.esRecurrente)
            .toList();

      case 'Variables':
        return obligations
            .where((obligation) => !obligation.esRecurrente)
            .toList();

      case 'Pagadas':
        return obligations
            .where(
              (obligation) =>
                  obligation.estado == ObligationService.estadoPagada,
            )
            .toList();

      default:
        return obligations;
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
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFD5E1ED)),
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
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
      decoration: const BoxDecoration(
        color: Colors.white,
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
                      ? 'Fija - ${obligation.frecuencia ?? 'Mensual'}'
                      : 'Variable - Mensual',
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
                          }
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

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                        title: 'Saldo disponible proyectado',
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

                  const SizedBox(height: 10),

                  obligations.isEmpty
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

                  const SizedBox(height: 12),

                  /// Botón para registrar una nueva obligación.
                  ///
                  /// Utiliza el mismo diseño visual de los
                  /// botones principales de Ingresos y Gastos.
                  SizedBox(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
