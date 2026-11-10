import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/report_provider.dart';
import '../../../shared/widgets/app_background.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/income_expense_chart.dart';
import '../widgets/expenses_by_category_chart.dart';
import '../widgets/savings_indicator.dart';
import '../../../data/services/report_pdf_service.dart';
import '../../../data/models/report_model.dart';
import '../../../shared/widgets/app_header.dart';

/// Tipos de período disponibles para consultar reportes.
enum ReportPeriod { monthly, yearly, custom }

/// Pantalla principal del módulo de Reportes.
class ReportsScreen extends StatefulWidget {
  // Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  // Acción ejecutada al pulsar la campana de notificaciones.
  final VoidCallback? onNotificationPressed;

  const ReportsScreen({
    super.key,
    this.onAvatarPressed,
    this.onNotificationPressed,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.monthly;

  // Último mes seleccionado.
  DateTime _monthlyDate = DateTime(DateTime.now().year, DateTime.now().month);

  // Último año seleccionado.
  int _yearlyYear = DateTime.now().year;

  // Último rango personalizado seleccionado.
  DateTime _customStartDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  DateTime _customEndDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );

  // Período que actualmente se está mostrando.
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

  DateTime _endDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );

  bool _initialReportLoaded = false;

  /// Exporta el reporte financiero actual a PDF.
  Future<void> _exportReport(ReportModel report) async {
    try {
      // Genera el PDF y abre su vista previa.
      await ReportPdfService.exportReport(report);
    } catch (e) {
      // Muestra un mensaje si ocurre algún error.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible generar el reporte PDF.')),
      );
    }
  }

  // Formato numérico colombiano.
  final NumberFormat _numberFormat = NumberFormat.decimalPattern('es_CO');

  /// Detecta si la aplicación utiliza el tema de alto contraste.
  bool _isHighContrast(BuildContext context) {
    return Theme.of(context).colorScheme.primary == const Color(0xFF003B8E);
  }

  /// Formatea los valores utilizando el símbolo $ al inicio.
  String _formatCurrency(double amount) {
    return '\$ ${_numberFormat.format(amount)}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Evita generar el reporte más de una vez.
    if (!_initialReportLoaded) {
      _initialReportLoaded = true;

      // Ejecuta la carga después de finalizar la construcción.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _generateReport();
        }
      });
    }
  }

  /// Solicita al provider la generación del reporte.
  Future<void> _generateReport() async {
    final authProvider = context.read<AuthProvider>();
    final usuario = authProvider.currentUser;

    if (usuario == null || usuario.idUsuario == null) return;

    await context.read<ReportProvider>().generateReport(
      idUsuario: usuario.idUsuario!,
      fechaInicio: _startDate,
      fechaFin: _endDate,
      ingresoFijoActual: usuario.ingresoFijoMensual,
    );
  }

  /// Cambia el tipo de filtro y recupera su última selección.
  void _changePeriod(ReportPeriod period) {
    setState(() {
      _selectedPeriod = period;

      switch (period) {
        case ReportPeriod.monthly:
          _startDate = DateTime(_monthlyDate.year, _monthlyDate.month, 1);
          _endDate = DateTime(_monthlyDate.year, _monthlyDate.month + 1, 0);
          break;

        case ReportPeriod.yearly:
          _startDate = DateTime(_yearlyYear, 1, 1);

          final hoy = DateTime.now();

          // El año actual termina hoy.
          // Los años anteriores terminan el 31 de diciembre.
          _endDate = _yearlyYear == hoy.year
              ? DateTime(hoy.year, hoy.month, hoy.day)
              : DateTime(_yearlyYear, 12, 31);
          break;

        case ReportPeriod.custom:
          _startDate = _customStartDate;
          _endDate = _customEndDate;
          break;
      }
    });

    // Genera el reporte correspondiente al filtro seleccionado.
    _generateReport();
  }

  /// Abre el selector correspondiente al filtro activo.
  Future<void> _openPeriodPicker() async {
    switch (_selectedPeriod) {
      case ReportPeriod.monthly:
        await _selectMonthly();
        break;

      case ReportPeriod.yearly:
        await _selectYearly();
        break;

      case ReportPeriod.custom:
        await _selectCustomPeriod();
        break;
    }
  }

  /// Permite seleccionar únicamente mes y año.
  Future<void> _selectMonthly() async {
    final selectedDate = await _showMonthYearPicker(_monthlyDate);

    if (selectedDate == null || !mounted) return;

    setState(() {
      _monthlyDate = DateTime(selectedDate.year, selectedDate.month);

      _startDate = DateTime(selectedDate.year, selectedDate.month, 1);

      _endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    });

    await _generateReport();
  }

  /// Muestra un diálogo para seleccionar mes y año.
  Future<DateTime?> _showMonthYearPicker(DateTime initialDate) async {
    final hoy = DateTime.now();

    int selectedMonth = initialDate.month;
    int selectedYear = initialDate.year;

    final bool highContrast = _isHighContrast(context);

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Limita los meses disponibles según el año seleccionado.
            final maxMonth = selectedYear == hoy.year ? hoy.month : 12;

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: highContrast
                    ? const BorderSide(color: Colors.black, width: 2)
                    : BorderSide.none,
              ),
              title: Text(
                'Seleccionar período mensual',
                style: TextStyle(color: highContrast ? Colors.black : null),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selector del mes.
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(maxMonth, (index) {
                      final month = index + 1;

                      return DropdownMenuItem<int>(
                        value: month,
                        child: Text(
                          DateFormat.MMMM(
                            'es_CO',
                          ).format(DateTime(2026, month)),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedMonth = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Selector del año.
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(hoy.year - 2000 + 1, (index) {
                      final year = 2000 + index;

                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedYear = value;

                        // Evita conservar un mes futuro.
                        final availableMonths = selectedYear == hoy.year
                            ? hoy.month
                            : 12;

                        if (selectedMonth > availableMonths) {
                          selectedMonth = availableMonths;
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      DateTime(selectedYear, selectedMonth),
                    );
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Permite seleccionar únicamente el año.
  Future<void> _selectYearly() async {
    final hoy = DateTime.now();

    int selectedYear = _yearlyYear;
    final bool highContrast = _isHighContrast(context);

    final year = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: highContrast
                    ? const BorderSide(color: Colors.black, width: 2)
                    : BorderSide.none,
              ),
              title: Text(
                'Seleccionar año',
                style: TextStyle(color: highContrast ? Colors.black : null),
              ),
              content: DropdownButtonFormField<int>(
                initialValue: selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Año',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(hoy.year - 2000 + 1, (index) {
                  final year = 2000 + index;

                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedYear = value;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selectedYear);
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (year == null || !mounted) return;

    final fechaInicio = DateTime(year, 1, 1);

    // El año actual termina hoy.
    // Los años anteriores terminan en diciembre.
    final fechaFin = year == hoy.year
        ? DateTime(hoy.year, hoy.month, hoy.day)
        : DateTime(year, 12, 31);

    setState(() {
      _yearlyYear = year;
      _startDate = fechaInicio;
      _endDate = fechaFin;
    });

    await _generateReport();
  }

  /// Permite seleccionar un rango de fechas personalizado.
  Future<void> _selectCustomPeriod() async {
    final hoy = DateTime.now();

    final bool highContrast = _isHighContrast(context);
    final ThemeData currentTheme = Theme.of(context);

    final selectedRange = await showDateRangePicker(
      context: context,
      builder: (context, child) {
        if (!highContrast) return child!;

        // Refuerza los colores del selector de fechas en alto contraste.
        return Theme(
          data: currentTheme.copyWith(
            colorScheme: currentTheme.colorScheme.copyWith(
              primary: const Color(0xFF003B8E),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textTheme: currentTheme.textTheme.apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ),
          ),
          child: child!,
        );
      },
      firstDate: DateTime(2000),
      lastDate: hoy,
      initialDateRange: DateTimeRange(
        start: _customStartDate,
        end: _customEndDate.isAfter(hoy) ? hoy : _customEndDate,
      ),
      helpText: 'Selecciona el período',
      saveText: 'Aceptar',
    );

    if (selectedRange == null || !mounted) return;

    setState(() {
      _customStartDate = selectedRange.start;
      _customEndDate = selectedRange.end;

      _startDate = selectedRange.start;
      _endDate = selectedRange.end;
    });

    await _generateReport();
  }

  @override
  Widget build(BuildContext context) {
    final bool highContrast = _isHighContrast(context);

    return Scaffold(
      backgroundColor: Colors.white,

      // Botón fijo para exportar el reporte PDF.
      bottomNavigationBar: Consumer<ReportProvider>(
        builder: (context, provider, child) {
          // Solo muestra el botón cuando existe un reporte disponible.
          if (provider.report == null ||
              provider.isLoading ||
              provider.errorMessage != null) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: highContrast
                    ? const Border(
                        top: BorderSide(color: Colors.black, width: 2),
                      )
                    : null,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _exportReport(provider.report!),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Exportar reporte PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: highContrast
                        ? const Color(0xFF003B8E)
                        : const Color(0xFF3F73BC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado reutilizable de la aplicación.
            AppHeader(
              title: 'Reportes',
              showAvatar: true,
              showNotification: true,
              onAvatarPressed: widget.onAvatarPressed,
              onNotificationPressed: widget.onNotificationPressed,
            ),

            // Contenido de los reportes.
            Expanded(
              child: AppBackground(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(context),
                      const SizedBox(height: 16),
                      _buildDateRange(context),
                      const SizedBox(height: 22),
                      _buildSummarySection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el selector de períodos.
  Widget _buildPeriodSelector(BuildContext context) {
    final bool highContrast = _isHighContrast(context);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: highContrast ? Border.all(color: Colors.black, width: 2) : null,
      ),
      child: Row(
        children: [
          _buildPeriodButton(context, 'Mensual', ReportPeriod.monthly),
          _buildPeriodButton(context, 'Anual', ReportPeriod.yearly),
          _buildPeriodButton(context, 'Personalizado', ReportPeriod.custom),
        ],
      ),
    );
  }

  /// Construye cada opción del selector.
  Widget _buildPeriodButton(
    BuildContext context,
    String title,
    ReportPeriod period,
  ) {
    final bool highContrast = _isHighContrast(context);
    final isSelected = _selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changePeriod(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? (highContrast
                      ? const Color(0xFF003B8E)
                      : const Color(0xFF3F73BC))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: highContrast && !isSelected
                ? Border.all(color: Colors.black, width: 1)
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (highContrast ? Colors.black : const Color(0xFF355C7D)),
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra el período seleccionado y permite modificarlo.
  Widget _buildDateRange(BuildContext context) {
    final bool highContrast = _isHighContrast(context);

    final Color primaryColor = highContrast
        ? const Color(0xFF003B8E)
        : const Color(0xFF3F73BC);

    final Color textColor = highContrast
        ? Colors.black
        : const Color(0xFF17324D);

    String periodText;

    switch (_selectedPeriod) {
      case ReportPeriod.monthly:
        periodText = DateFormat('MMMM yyyy', 'es_CO').format(_monthlyDate);
        break;

      case ReportPeriod.yearly:
        periodText = _yearlyYear.toString();
        break;

      case ReportPeriod.custom:
        final dateFormat = DateFormat('dd/MM/yyyy');

        periodText =
            '${dateFormat.format(_customStartDate)} - '
            '${dateFormat.format(_customEndDate)}';
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openPeriodPicker,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: highContrast
                ? Border.all(color: Colors.black, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  periodText,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.edit_calendar_outlined, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el resumen financiero y los gráficos del reporte.
  Widget _buildSummarySection() {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        final bool highContrast = _isHighContrast(context);

        final Color textColor = highContrast
            ? Colors.black
            : const Color(0xFF17324D);

        // Muestra el indicador de carga.
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Muestra los errores del reporte.
        if (provider.errorMessage != null) {
          return Center(
            child: Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: highContrast ? Colors.black : Colors.red),
            ),
          );
        }

        final report = provider.report;

        // Comprueba que exista información.
        if (report == null) {
          return Center(
            child: Text(
              'No hay información disponible para este período.',
              style: TextStyle(color: textColor),
            ),
          );
        }

        // Comprueba si existen movimientos financieros.
        final hasMovements = report.totalIngresos > 0 || report.totalGastos > 0;

        // Tarjeta de ingresos.
        final incomeCard = ReportSummaryCard(
          title: 'Ingresos',
          amount: _formatCurrency(report.totalIngresos),
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF16A765),
          backgroundColor: const Color(0xFFD7F3E5),
        );

        // Tarjeta de gastos.
        final expenseCard = ReportSummaryCard(
          title: 'Gastos',
          amount: _formatCurrency(report.totalGastos),
          icon: Icons.trending_down_rounded,
          color: const Color(0xFFE05252),
          backgroundColor: const Color(0xFFFFDADA),
        );

        // Tarjeta de saldo disponible.
        final balanceCard = ReportSummaryCard(
          title: 'Saldo disponible',
          amount: _formatCurrency(report.saldo),
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFF3F73BC),
          backgroundColor: const Color(0xFFDCEAFF),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenedor principal del resumen financiero.
            Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: highContrast
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
                boxShadow: highContrast
                    ? const []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.09),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado azul de la tarjeta principal.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: highContrast ? const Color(0xFF003B8E) : null,
                      gradient: highContrast
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF2459A6), Color(0xFF4A86D8)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                    ),
                    child: const Text(
                      'Resumen financiero',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Cuerpo blanco con las tres tarjetas.
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        // Primera fila: ingresos y gastos.
                        Row(
                          children: [
                            Expanded(child: incomeCard),
                            const SizedBox(width: 10),
                            Expanded(child: expenseCard),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Segunda fila: saldo disponible centrado.
                        Center(child: SizedBox(width: 220, child: balanceCard)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Mensaje cuando no existen movimientos.
            if (!hasMovements)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: highContrast
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.insert_chart_outlined,
                      size: 35,
                      color: highContrast
                          ? const Color(0xFF003B8E)
                          : const Color(0xFF3F73BC),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sin movimientos registrados',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Cuando registres ingresos o gastos '
                      'durante este período, aparecerán aquí.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: highContrast
                            ? Colors.black
                            : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),

            // Gráfico comparativo.
            IncomeExpenseChart(
              totalIngresos: report.totalIngresos,
              totalGastos: report.totalGastos,
            ),
            const SizedBox(height: 20),

            // Gastos por categoría.
            ExpensesByCategoryChart(categories: report.gastosPorCategoria),
            const SizedBox(height: 20),

            // Porcentaje de ahorro.
            SavingsIndicator(
              totalIngresos: report.totalIngresos,
              saldo: report.saldo,
            ),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
