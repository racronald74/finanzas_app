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

  /// Muestra una confirmación antes de eliminar la meta.
  Future<void> _deleteGoal() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar meta'),
          content: Text(
            '¿Estás seguro de que deseas eliminar la meta '
            '"${_goal.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await GoalService().eliminarMeta(
        idMeta: _goal.idMeta!,
        idUsuario: _goal.idUsuario,
      );

      if (!mounted) {
        return;
      }

      // Regresa a la lista de metas indicando que
      // la meta fue eliminada correctamente.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible eliminar la meta: $e')),
      );
    }
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
                      onDelete: _deleteGoal,
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

                    const SizedBox(height: 8),

                    Consumer<ContributionProvider>(
                      builder: (context, contributionProvider, child) {
                        final double? averageMonthly =
                            _calculateAverageMonthlyContribution(
                              contributionProvider.contributions,
                            );

                        final DateTime today = DateTime.now();

                        int monthsRemaining =
                            (_goal.fechaLimite.year - today.year) * 12 +
                            _goal.fechaLimite.month -
                            today.month;

                        if (monthsRemaining < 1) {
                          monthsRemaining = 1;
                        }

                        final double projectedAdditionalAmount =
                            averageMonthly != null
                            ? averageMonthly * monthsRemaining
                            : 0;

                        final double projectedAmount =
                            (_goal.montoAcumulado + projectedAdditionalAmount)
                                .clamp(0, _goal.montoObjetivo);

                        final bool projectedToReachGoal =
                            projectedAmount >= _goal.montoObjetivo;

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: projectedToReachGoal
                                ? AppColors.success.withValues(alpha: 0.10)
                                : AppColors.warning.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            projectedToReachGoal
                                ? 'Con tu ritmo actual, alcanzarías la meta antes de la fecha límite.'
                                : 'Con tu ritmo actual, no alcanzarías el monto objetivo antes de la fecha límite.',
                            style: TextStyle(
                              color: projectedToReachGoal
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
}

/// Tarjeta que muestra el resumen principal de la meta.
class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({
    required this.goal,
    required this.progress,
    required this.remainingAmount,
    required this.onDelete,
  });

  final GoalModel goal;
  final double progress;
  final double remainingAmount;
  final VoidCallback onDelete;

  String _formatCreatedDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        'de ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // Fecha límite y estado
            // ============================================
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: AppColors.primary,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Fecha límite ${_formatDate(goal.fechaLimite)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Eliminar meta',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),

                    const SizedBox(width: 4),

                    _StatusChip(status: goal.status),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ============================================
            // Monto y progreso
            // ============================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información monetaria.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monto actual / objetivo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 4),

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
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.insights,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Has ahorrado '
                                  '${CurrencyFormatter.format(goal.montoAcumulado)}',
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 2),

                            Text(
                              'desde ${goal.createdAt != null ? _formatCreatedDate(goal.createdAt!) : ''}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Progreso y eliminación.
                SizedBox(
                  width: 125,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Porcentaje.
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 58,
                            height: 58,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 6,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.12,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Texto debajo del círculo.
                      Text(
                        'Faltan ${CurrencyFormatter.format(remainingAmount)}\n'
                        'para alcanzar tu meta',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        softWrap: false,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),
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
