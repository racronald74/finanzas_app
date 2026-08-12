import 'package:flutter/material.dart';

import '../../../data/models/goal_model.dart';
import '../../../shared/helpers/currency_formatter.dart';
import '../../../shared/themes/app_colors.dart';
import '../../../shared/widgets/app_header.dart';
import 'add_contribution_screen.dart';
import '../../../data/services/goal_service.dart';
import '../../../data/models/contribution_model.dart';
import '../../../providers/contribution_provider.dart';
import 'package:provider/provider.dart';
import 'edit_goal_screen.dart';

/// Pantalla que muestra el detalle completo de una meta.
///
/// Esta pantalla recibe una meta existente y presenta
/// la información disponible actualmente en GoalModel.
///
/// El historial de aportes y la proyección de ahorro
class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key, required this.goal});

  /// Meta inicial que se muestra al abrir el detalle.
  final GoalModel goal;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  /// Meta actualmente cargada desde SQLite.
  late GoalModel _goal;

  @override
  void initState() {
    super.initState();

    // Conserva inicialmente la meta recibida desde la pantalla anterior.
    _goal = widget.goal;

    // Carga el historial de aportes después de construir la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContributions();
    });
  }

  /// Recarga la meta desde SQLite.
  Future<void> _reloadGoal() async {
    final GoalModel? updatedGoal = await GoalService().obtenerMetaPorIdMeta(
      _goal.idMeta!,
    );

    if (updatedGoal == null || !mounted) {
      return;
    }

    setState(() {
      _goal = updatedGoal;
    });
  }

  /// Carga el historial de aportes de la meta.
  Future<void> _loadContributions() async {
    await context.read<ContributionProvider>().loadContributions(_goal.idMeta!);
  }

  @override
  Widget build(BuildContext context) {
    // Calcula el monto que todavía falta para completar la meta.
    final double remainingAmount = (_goal.montoObjetivo - _goal.montoAcumulado)
        .clamp(0, double.infinity);

    // Calcula el porcentaje de avance de la meta.
    final double progress = _goal.montoObjetivo > 0
        ? (_goal.montoAcumulado / _goal.montoObjetivo).clamp(0, 1)
        : 0;

    // Calcula cuánto debería aportar mensualmente
    // para alcanzar la meta antes de la fecha límite.
    final double monthlyGoal = GoalService().calcularAporteMensual(_goal);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            /// Encabezado de la pantalla.
            AppHeader(
              title: _goal.nombre,
              showBackButton: true,
              showAvatar: true,
            ),

            /// Contenido principal.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================
                    // Resumen principal de la meta
                    // ============================================
                    _GoalSummaryCard(
                      goal: _goal,
                      progress: progress,
                      remainingAmount: remainingAmount,
                    ),

                    const SizedBox(height: 16),

                    // Actualiza las tarjetas de ahorro cuando cambian
                    // los aportes registrados.
                    Consumer<ContributionProvider>(
                      builder: (context, contributionProvider, child) {
                        // Calcula el promedio mensual utilizando
                        // los aportes registrados de la meta.
                        final double? averageMonthly =
                            _calculateAverageMonthlyContribution(
                              contributionProvider.contributions,
                            );

                        return _SavingsInformationCard(
                          goal: _goal,
                          monthlyGoal: monthlyGoal,
                          averageMonthly: averageMonthly,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ============================================
                    // Historial de aportes
                    // ============================================
                    Consumer<ContributionProvider>(
                      builder: (context, contributionProvider, child) {
                        return _ContributionHistoryCard(
                          contributions: contributionProvider.contributions,
                          isLoading: contributionProvider.isLoading,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ============================================
                    // Proyección de ahorro
                    // ============================================
                    Consumer<ContributionProvider>(
                      builder: (context, contributionProvider, child) {
                        // Obtiene los aportes registrados para la meta.
                        final List<ContributionModel> contributions =
                            contributionProvider.contributions;

                        // Calcula el promedio mensual disponible para la proyección.
                        //
                        // Puede ser null cuando todavía no existe suficiente
                        // historial de aportes para realizar una proyección confiable.
                        final double? averageMonthly =
                            _calculateAverageMonthlyContribution(contributions);

                        // Calcula aproximadamente cuántos meses quedan
                        // hasta la fecha límite de la meta.
                        final DateTime today = DateTime.now();

                        int monthsRemaining =
                            (_goal.deadline.year - today.year) * 12 +
                            _goal.deadline.month -
                            today.month;

                        // Como mínimo consideramos un mes disponible.
                        if (monthsRemaining < 1) {
                          monthsRemaining = 1;
                        }

                        // Calcula el ahorro adicional proyectado únicamente
                        // cuando existe suficiente historial para obtener
                        // un promedio mensual confiable.
                        final double projectedAdditionalAmount =
                            averageMonthly != null
                            ? averageMonthly * monthsRemaining
                            : 0;

                        // Genera los valores que utilizará la gráfica
                        // para representar la evolución proyectada del ahorro.
                        final List<double> projectionValues =
                            averageMonthly != null
                            ? _buildProjectionValues(
                                averageMonthly: averageMonthly,
                                monthsRemaining: monthsRemaining,
                              )
                            : [];

                        // Calcula cuánto dinero tendría la meta al final
                        // del período proyectado.
                        //
                        // No permitimos que la proyección supere el
                        // monto objetivo.
                        final double projectedAmount =
                            (_goal.savedAmount + projectedAdditionalAmount)
                                .clamp(0, _goal.targetAmount);

                        // Determina si el ritmo actual permitiría
                        // alcanzar el objetivo.
                        final bool projectedToReachGoal =
                            projectedAmount >= _goal.targetAmount;

                        return _SectionCard(
                          title: 'Proyección de ahorro',

                          // Si no existe suficiente historial, todavía
                          // no se calcula una proyección confiable.
                          child: contributions.isEmpty || averageMonthly == null
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                    'Aún no hay suficiente historial de aportes '
                                    'para calcular una proyección confiable.',
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              // Cuando existen aportes, mostramos
                              // los resultados de la proyección.
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Promedio mensual calculado a partir
                                    // de los aportes registrados.
                                    _ProjectionRow(
                                      label: 'Aporte mensual promedio',
                                      value: CurrencyFormatter.format(
                                        averageMonthly,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Cantidad aproximada de meses restantes
                                    // hasta la fecha límite.
                                    _ProjectionRow(
                                      label: 'Meses restantes',
                                      value: monthsRemaining.toString(),
                                    ),

                                    const SizedBox(height: 12),

                                    // Monto que se estima tener al llegar
                                    // a la fecha límite.
                                    _ProjectionRow(
                                      label: 'Monto proyectado',
                                      value: CurrencyFormatter.format(
                                        projectedAmount,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    const SizedBox(height: 20),

                                    // Muestra gráficamente la evolución proyectada
                                    // comenzando desde el mes actual.
                                    _ProjectionChart(
                                      values: projectionValues,
                                      targetAmount: _goal.targetAmount,
                                      startDate: DateTime.now(),
                                    ),

                                    // Mensaje indicando si el ritmo actual
                                    // sería suficiente para alcanzar la meta.
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: projectedToReachGoal
                                            ? AppColors.success.withValues(
                                                alpha: 0.10,
                                              )
                                            : AppColors.warning.withValues(
                                                alpha: 0.10,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        projectedToReachGoal
                                            ? 'Con tu ritmo actual, alcanzarías '
                                                  'la meta antes de la fecha límite.'
                                            : 'Con tu ritmo actual, no alcanzarías '
                                                  'el monto objetivo antes de la '
                                                  'fecha límite.',
                                        style: TextStyle(
                                          color: projectedToReachGoal
                                              ? AppColors.success
                                              : AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ============================================
                    // Resumen final
                    // ============================================
                    _GoalFinalSummaryCard(goal: _goal),

                    const SizedBox(height: 20),

                    // ============================================
                    // Acciones
                    // ============================================
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Abre la pantalla para registrar un nuevo aporte.
                              final bool? contributionCreated =
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddContributionScreen(goal: _goal),
                                    ),
                                  );

                              // Si se registró un aporte correctamente,
                              // la pantalla se actualizará en el siguiente paso.
                              if (contributionCreated == true &&
                                  context.mounted) {
                                // Actualiza la información general de la meta.
                                await _reloadGoal();

                                // Actualiza el historial de aportes.
                                await _loadContributions();
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Registrar aporte'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final bool? goalUpdated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditGoalScreen(goal: _goal),
                                ),
                              );

                              if (goalUpdated == true && context.mounted) {
                                // Recarga la meta después de guardar los cambios.
                                await _reloadGoal();
                              }
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar meta'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calcula el promedio mensual de aportes.
  ///
  /// Se consideran todos los meses desde el primer aporte
  /// hasta el mes actual, incluyendo los meses en los que
  /// no se realizaron aportes.
  ///
  /// Retorna null cuando todavía no existe suficiente historial
  /// para realizar una proyección confiable.
  double? _calculateAverageMonthlyContribution(
    List<ContributionModel> contributions,
  ) {
    // Sin aportes no existe información para calcular
    // un promedio mensual.
    if (contributions.isEmpty) {
      return null;
    }

    // Ordena los aportes desde el más antiguo
    // hasta el más reciente.
    final List<ContributionModel> sortedContributions = [...contributions]
      ..sort(
        (a, b) => DateTime.parse(a.fecha).compareTo(DateTime.parse(b.fecha)),
      );

    // Obtiene la fecha del primer aporte registrado.
    final DateTime firstDate = DateTime.parse(sortedContributions.first.fecha);

    // Obtiene el mes actual.
    final DateTime today = DateTime.now();

    // Calcula cuántos meses existen entre el primer aporte
    // y el mes actual, incluyendo ambos extremos.
    final int months =
        (today.year - firstDate.year) * 12 + today.month - firstDate.month + 1;

    // Con un solo mes de historial todavía no consideramos
    // que exista suficiente información para proyectar.
    if (months < 2) {
      return null;
    }

    // Suma todos los aportes registrados.
    final double total = sortedContributions.fold(
      0,
      (sum, contribution) => sum + contribution.monto,
    );

    // Divide el total entre todos los meses del período.
    //
    // Esto hace que los meses sin aportes también formen
    // parte del promedio y evita sobreestimar la capacidad
    // mensual de ahorro.
    return total / months;
  }

  /// Genera los valores de ahorro proyectados para cada mes.
  ///
  /// El primer valor corresponde al ahorro acumulado actualmente.
  /// Cada mes posterior suma el aporte mensual promedio.
  /// La proyección nunca supera el monto objetivo.
  List<double> _buildProjectionValues({
    required double averageMonthly,
    required int monthsRemaining,
  }) {
    // Lista que almacenará el ahorro estimado para cada período.
    final List<double> values = [];

    // El primer punto representa el ahorro actual de la meta.
    double projectedAmount = _goal.savedAmount;

    values.add(projectedAmount);

    // Genera un punto por cada mes restante.
    for (int month = 1; month <= monthsRemaining; month++) {
      // Suma el promedio mensual al ahorro proyectado.
      projectedAmount += averageMonthly;

      // La proyección no puede superar el objetivo de la meta.
      if (projectedAmount > _goal.targetAmount) {
        projectedAmount = _goal.targetAmount;
      }

      values.add(projectedAmount);
    }

    return values;
  }
}

/// Gráfico que representa la evolución proyectada
/// del ahorro hasta la fecha límite.
class _ProjectionChart extends StatelessWidget {
  const _ProjectionChart({
    required this.values,
    required this.targetAmount,
    required this.startDate,
  });

  /// Valores de ahorro proyectados para cada período.
  final List<double> values;

  /// Monto objetivo de la meta.
  final double targetAmount;

  /// Fecha utilizada como punto inicial del gráfico.
  final DateTime startDate;

  @override
  Widget build(BuildContext context) {
    // Si no existen suficientes datos, no se muestra el gráfico.
    if (values.length < 2) {
      return const SizedBox.shrink();
    }

    // Obtiene el valor máximo utilizado por el gráfico.
    // Como mínimo utilizamos el monto objetivo para mantener
    // una escala estable.
    final double maxValue = targetAmount > 0
        ? targetAmount
        : values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: CustomPaint(
        painter: _ProjectionChartPainter(
          values: values,
          maxValue: maxValue,
          startDate: startDate,
        ),
      ),
    );
  }
}

/// Painter encargado de dibujar la línea de proyección.
class _ProjectionChartPainter extends CustomPainter {
  const _ProjectionChartPainter({
    required this.values,
    required this.maxValue,
    required this.startDate,
  });

  /// Valores que representan el ahorro proyectado.
  final List<double> values;

  /// Valor máximo utilizado para calcular la escala vertical.
  final double maxValue;

  /// Mes desde el cual comienza la proyección.
  final DateTime startDate;

  /// Devuelve la abreviatura del mes utilizada en el gráfico.
  String _getMonthAbbreviation(int month) {
    const List<String> months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return months[month - 1];
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Configura el estilo de la línea de proyección.
    final Paint linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Configura el estilo de los puntos.
    final Paint pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    // Configura la línea que representa el monto objetivo.
    final Paint targetPaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Calcula la posición vertical correspondiente
    // al monto objetivo.
    final double targetY = size.height - 28;

    // Dibuja una línea horizontal como referencia
    // del objetivo de ahorro.
    canvas.drawLine(
      Offset(0, targetY),
      Offset(size.width, targetY),
      targetPaint,
    );

    // Formatea el monto objetivo para mostrarlo
    // como referencia dentro del gráfico.
    final String targetLabel = CurrencyFormatter.format(maxValue);

    // Configura el texto que identifica el objetivo.
    final TextPainter targetTextPainter = TextPainter(
      text: TextSpan(
        text: targetLabel,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    // Calcula el tamaño necesario para el texto.
    targetTextPainter.layout();

    // Coloca la etiqueta en la parte superior
    // del área de la gráfica.
    targetTextPainter.paint(
      canvas,
      Offset(0, targetY - targetTextPainter.height - 4),
    );

    // Calcula la separación horizontal entre cada punto.
    final double horizontalStep = size.width / (values.length - 1);

    final Path path = Path();

    for (int index = 0; index < values.length; index++) {
      // Convierte el valor monetario en una posición vertical.
      final double normalizedValue = maxValue > 0
          ? values[index] / maxValue
          : 0;

      final double x = index * horizontalStep;

      // El eje vertical comienza arriba y aumenta hacia abajo,
      // por eso invertimos el valor normalizado.
      // Reservamos espacio en la parte inferior del gráfico
      // para mostrar las etiquetas de los meses.
      final double chartHeight = size.height - 28;

      // Calcula la posición vertical del punto dentro
      // del área reservada para la gráfica.
      final double y = chartHeight - (normalizedValue * chartHeight);

      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Dibuja un punto en cada valor proyectado.
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    // Dibuja la línea que conecta los puntos.
    canvas.drawPath(path, linePaint);

    // Configura el estilo de las etiquetas de los meses.
    const TextStyle monthTextStyle = TextStyle(
      fontSize: 12,
      color: AppColors.textSecondary,
    );

    // Dibuja el mes correspondiente debajo de cada punto.
    for (int index = 0; index < values.length; index++) {
      // Calcula la fecha correspondiente al punto actual.
      final DateTime monthDate = DateTime(
        startDate.year,
        startDate.month + index,
      );

      // Obtiene una abreviatura sencilla del mes.
      final String month = _getMonthAbbreviation(monthDate.month);

      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: month, style: monthTextStyle),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Calcula la posición horizontal de la etiqueta.
      final double x = (index * horizontalStep) - (textPainter.width / 2);

      // Coloca la etiqueta dentro del espacio reservado
      // en la parte inferior del gráfico.
      final double y = size.height - 20;

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectionChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.maxValue != maxValue;
  }
}

/// Tarjeta que muestra el resumen principal de la meta.
class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({
    required this.goal,
    required this.progress,
    required this.remainingAmount,
  });

  final GoalModel goal;
  final double progress;
  final double remainingAmount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Información superior.
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text('Fecha límite ${_formatDate(goal.fechaLimite)}'),
                    ],
                  ),
                ),

                // Estado de la meta.
                _StatusChip(status: goal.status),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Valores monetarios.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monto actual / objetivo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 6),

                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: CurrencyFormatter.format(
                                goal.montoAcumulado,
                              ),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' / ${CurrencyFormatter.format(goal.montoObjetivo)}',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Mensaje de ahorro acumulado.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Has ahorrado '
                          '${CurrencyFormatter.format(goal.montoAcumulado)}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Indicador circular del progreso.
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Faltan ${CurrencyFormatter.format(remainingAmount)} '
                'para alcanzar tu meta',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con información relacionada con el ahorro de la meta.
class _SavingsInformationCard extends StatelessWidget {
  const _SavingsInformationCard({
    required this.goal,
    required this.monthlyGoal,
    required this.averageMonthly,
  });

  /// Meta que se está mostrando.
  final GoalModel goal;

  /// Aporte mensual necesario para alcanzar la meta.
  final double monthlyGoal;

  /// Promedio mensual de los aportes realizados.
  /// Puede ser null si no existe suficiente historial.
  final double? averageMonthly;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InformationItem(
            icon: Icons.attach_money,
            title: 'Aporte mensual sugerido',
            value: CurrencyFormatter.format(monthlyGoal),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _InformationItem(
            icon: Icons.access_time,
            title: 'Tiempo restante',
            value: _calculateRemainingTime(goal.fechaLimite),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: _InformationItem(
            icon: Icons.bar_chart,
            title: 'Promedio ahorro',
            value: averageMonthly == null
                ? 'Sin datos'
                : CurrencyFormatter.format(averageMonthly!),
          ),
        ),
      ],
    );
  }
}

/// Elemento individual de información.
class _InformationItem extends StatelessWidget {
  const _InformationItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 105),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary),

          const SizedBox(height: 6),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta reutilizable para las diferentes secciones del detalle.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            child,
          ],
        ),
      ),
    );
  }
}

/// Tarjeta con el resumen final de la meta.
class _GoalFinalSummaryCard extends StatelessWidget {
  const _GoalFinalSummaryCard({required this.goal});

  final GoalModel goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Meta objetivo'),
              Text(
                CurrencyFormatter.format(goal.montoObjetivo),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fecha límite'),
              Text(
                _formatDate(goal.fechaLimite),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip que muestra el estado de la meta.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tarjeta que muestra el historial de aportes de una meta.
class _ContributionHistoryCard extends StatelessWidget {
  const _ContributionHistoryCard({
    required this.contributions,
    required this.isLoading,
  });

  /// Aportes registrados para la meta.
  final List<ContributionModel> contributions;

  /// Indica si se están cargando los aportes.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(title: 'Historial de aportes', child: _buildContent());
  }

  /// Construye el contenido dependiendo del estado
  /// del historial.
  Widget _buildContent() {
    if (isLoading && contributions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Estado vacío cuando todavía no existen aportes.
    if (contributions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Aún no existen aportes asociados a esta meta.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Muestra los aportes registrados.
    return Column(
      children: contributions.map((contribution) {
        return _ContributionItem(contribution: contribution);
      }).toList(),
    );
  }
}

/// Representa un aporte individual dentro del historial.
class _ContributionItem extends StatelessWidget {
  const _ContributionItem({required this.contribution});

  final ContributionModel contribution;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          // Indicador visual del aporte.
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.success.withValues(alpha: 0.15),
            child: const Icon(Icons.arrow_upward, color: AppColors.success),
          ),

          const SizedBox(width: 12),

          // Fecha y método del aporte.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatContributionDate(contribution.fecha),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 4),

                Text(
                  contribution.origen,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Monto del aporte.
          Text(
            '+ ${CurrencyFormatter.format(contribution.monto)}',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatContributionDate(String date) {
  final DateTime? parsedDate = DateTime.tryParse(date);

  if (parsedDate == null) {
    return date;
  }

  return '${parsedDate.day.toString().padLeft(2, '0')}/'
      '${parsedDate.month.toString().padLeft(2, '0')}/'
      '${parsedDate.year}';
}

/// Convierte una fecha en formato legible para la interfaz.
String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

/// Calcula de forma sencilla el tiempo restante hasta la fecha límite.
String _calculateRemainingTime(DateTime deadline) {
  final DateTime today = DateTime.now();

  if (deadline.isBefore(today)) {
    return 'Vencida';
  }

  final int months =
      (deadline.year - today.year) * 12 + deadline.month - today.month;

  if (months <= 0) {
    final int days = deadline.difference(today).inDays;
    return '$days días';
  }

  return '$months meses';
}

/// Fila reutilizable utilizada para mostrar
/// un dato de la proyección y su valor.
class _ProjectionRow extends StatelessWidget {
  const _ProjectionRow({required this.label, required this.value});

  /// Nombre del dato que se está mostrando.
  final String label;

  /// Valor calculado de ese dato.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Permite que el texto ocupe el espacio disponible
        // sin provocar problemas de ancho.
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),

        const SizedBox(width: 12),

        // Muestra el valor calculado.
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
