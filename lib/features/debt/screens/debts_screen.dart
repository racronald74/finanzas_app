import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/debt_provider.dart';
import '../../../data/models/debt_model.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../widgets/debt_card.dart';
import '../widgets/debt_summary_card.dart';
import 'create_debt_screen.dart';
import '../../../shared/themes/app_colors.dart';
import 'debt_detail_screen.dart';
import 'register_debt_payment_screen.dart';

/// Pantalla principal del módulo Deudas.
///
/// Permite:
/// - Visualizar el resumen general de las deudas.
/// - Filtrar las deudas por estado.
/// - Consultar el listado de deudas.
/// - Acceder posteriormente al detalle de una deuda.
/// - Registrar una nueva deuda.
class DebtsScreen extends StatefulWidget {
  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  const DebtsScreen({super.key, this.onAvatarPressed});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  /// Filtro seleccionado actualmente.
  String _selectedFilter = 'Todas';

  /// Filtros definidos para el módulo de deudas.
  /// Filtros disponibles para el módulo de deudas.
  static const List<String> _filters = [
    'Todas',
    'Activas',
    'Vencidas',
    'Pagadas',
  ];

  @override
  void initState() {
    super.initState();

    /// Carga las deudas después de construir la pantalla,
    /// permitiendo acceder correctamente a los Providers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDebts();
    });
  }

  /// Carga las deudas del usuario autenticado.
  Future<void> _loadDebts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final debtProvider = Provider.of<DebtProvider>(context, listen: false);

    final user = authProvider.currentUser;

    if (user == null) return;

    await debtProvider.loadDebts(user.idUsuario!);
  }

  /// Calcula la fecha de vencimiento sumando el plazo a la fecha de inicio.
  DateTime? _calculateDueDate(DebtModel debt) {
    final DateTime? startDate = DateTime.tryParse(debt.fechaInicio);

    if (startDate == null || debt.plazo == null) {
      return null;
    }

    // Calcula el mes de vencimiento.
    final DateTime targetMonth = DateTime(
      startDate.year,
      startDate.month + debt.plazo!,
      1,
    );

    // Obtiene el último día del mes de vencimiento.
    final int lastDay = DateTime(
      targetMonth.year,
      targetMonth.month + 1,
      0,
    ).day;

    // Evita fechas inválidas en meses con menos días.
    final int day = startDate.day > lastDay ? lastDay : startDate.day;

    return DateTime(targetMonth.year, targetMonth.month, day);
  }

  /// Comprueba si una deuda tiene vencido su plazo y conserva saldo pendiente.
  bool _isOverdue(DebtModel debt) {
    if (debt.estado == 'Pagada' || debt.saldoPendiente <= 0) {
      return false;
    }

    final DateTime? dueDate = _calculateDueDate(debt);

    if (dueDate == null) return false;

    final DateTime today = DateTime.now();

    final DateTime currentDate = DateTime(today.year, today.month, today.day);

    return currentDate.isAfter(dueDate);
  }

  /// Devuelve las deudas correspondientes al filtro seleccionado.
  List<DebtModel> _filterDebts(List<DebtModel> debts) {
    switch (_selectedFilter) {
      case 'Activas':
        return debts.where((debt) {
          return debt.saldoPendiente > 0 && !_isOverdue(debt);
        }).toList();

      case 'Vencidas':
        return debts.where(_isOverdue).toList();

      case 'Pagadas':
        return debts.where((debt) {
          return debt.estado == 'Pagada' || debt.saldoPendiente <= 0;
        }).toList();

      case 'Todas':
      default:
        return debts;
    }
  }

  /// Cambia el filtro seleccionado.
  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final debtProvider = Provider.of<DebtProvider>(context);
    final debts = _filterDebts(debtProvider.debts);

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Deudas',
            showAvatar: true,
            showNotification: true,
            onAvatarPressed: widget.onAvatarPressed,
          ),

          Expanded(
            child: AppBackground(
              child: Column(
                children: [
                  // Tarjeta resumen.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: DebtSummaryCard(debts: debtProvider.debts),
                  ),

                  const SizedBox(height: 8),

                  // Filtros adaptativos.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: _buildFilterButton(filter),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Listado o estado vacío.
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: _buildContent(
                        debtProvider: debtProvider,
                        debts: debts,
                      ),
                    ),
                  ),

                  // Botón para crear una nueva deuda.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreateDebtScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Crear deuda',
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
        ],
      ),
    );
  }

  /// Construye el contenido dependiendo del estado del Provider.
  Widget _buildContent({
    required DebtProvider debtProvider,
    required List<DebtModel> debts,
  }) {
    if (debtProvider.isLoading && debtProvider.debts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (debtProvider.errorMessage != null && debtProvider.debts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(debtProvider.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadDebts, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (debts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listado de deudas (${debts.length})',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        ...debts.map(
          (debt) => DebtCard(
            debt: debt,
            // Abre el detalle de la deuda seleccionada.
            onDetail: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DebtDetailScreen(debt: debt)),
              );
            },
            onPay: () async {
              // Abre el formulario de pago de la deuda seleccionada.
              final bool? registered = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => RegisterDebtPaymentScreen(debt: debt),
                ),
              );

              // Actualiza el listado cuando se registra un pago.
              if (registered == true && mounted) {
                await _loadDebts();
              }
            },
          ),
        ),
      ],
    );
  }

  /// Estado vacío cuando no existen deudas.
  Widget _buildEmptyState() {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono representativo del módulo de deudas.
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 32,
                color: Color(0xFF2196F3),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'No tienes deudas registradas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF171717),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Registra tus deudas para llevar un mejor '
              'control de tus pagos y saldos pendientes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye cada botón de filtro.
  Widget _buildFilterButton(String filter) {
    final bool isSelected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () => _selectFilter(filter),
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          filter,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
