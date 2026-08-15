import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/goal_provider.dart';
import '../../../shared/widgets/app_header.dart';
import '../widgets/goal_overview_card.dart';
import '../widgets/goal_card.dart';
import 'add_goal_screen.dart';
import '../../../shared/helpers/currency_formatter.dart';
import 'goal_detail_screen.dart';
import 'add_contribution_screen.dart';
import '../../../shared/themes/app_colors.dart';

/// Pantalla principal del módulo Metas.
class GoalsScreen extends StatefulWidget {
  /// Acción ejecutada al pulsar el avatar.
  final VoidCallback? onAvatarPressed;

  const GoalsScreen({super.key, this.onAvatarPressed});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();

    // Carga las metas después de construir la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoals();
    });
  }

  /// Carga las metas correspondientes al usuario autenticado.
  Future<void> _loadGoals() async {
    final authProvider = context.read<AuthProvider>();
    final goalProvider = context.read<GoalProvider>();

    final usuario = authProvider.currentUser;

    // No se pueden cargar metas si no existe un usuario autenticado.
    if (usuario == null || usuario.idUsuario == null) {
      return;
    }

    await goalProvider.loadGoals(usuario.idUsuario!);
  }

  /// Obtiene el icono correspondiente a la categoría de la meta.
  IconData _getGoalIcon(String category) {
    switch (category) {
      case 'Viajes':
        return Icons.beach_access;

      case 'Vivienda':
        return Icons.home;

      case 'Vehículo':
        return Icons.directions_car;

      case 'Educación':
        return Icons.school;

      case 'Tecnología':
        return Icons.laptop_mac;

      case 'Salud':
        return Icons.favorite;

      default:
        return Icons.flag_outlined;
    }
  }

  /// Convierte una fecha DateTime al formato utilizado
  /// visualmente en las tarjetas de metas.
  String _formatDeadline(DateTime deadline) {
    return '${deadline.day.toString().padLeft(2, '0')}/'
        '${deadline.month.toString().padLeft(2, '0')}/'
        '${deadline.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Metas',
            showAvatar: true,
            showNotification: true,
            onAvatarPressed: widget.onAvatarPressed,
          ),

          Expanded(
            child: Consumer<GoalProvider>(
              builder: (context, goalProvider, child) {
                // Muestra un indicador mientras se cargan las metas.
                if (goalProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Muestra un mensaje si ocurrió un error.
                if (goalProvider.errorMessage != null) {
                  return Center(
                    child: Text(
                      goalProvider.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final goals = goalProvider.goals;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de resumen del módulo.
                      GoalOverviewCard(
                        totalSavings: goalProvider.totalSavings,
                        activeGoals: goalProvider.activeGoals,
                        totalProgress: goalProvider.totalProgress,
                        monthlyGoal: goalProvider.monthlyGoal,
                        messageTitle: 'Objetivo mensual estimado',
                        message:
                            'Para alcanzar tus metas a tiempo, procura aportar aproximadamente '
                            '${CurrencyFormatter.format(goalProvider.monthlyGoal)} este mes.',
                      ),

                      const SizedBox(height: 20),

                      // Título de la sección.
                      const Text(
                        'Mis metas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Muestra las metas almacenadas en SQLite.
                      if (goals.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Text('No tienes metas registradas.'),
                          ),
                        )
                      else
                        ...goals.map((goal) {
                          // Calcula el progreso de la meta.
                          final double progress = goal.targetAmount > 0
                              ? (goal.savedAmount / goal.targetAmount).clamp(
                                  0.0,
                                  1.0,
                                )
                              : 0.0;

                          return GoalCard(
                            icon: _getGoalIcon(goal.category),
                            title: goal.name,
                            description: goal.category,
                            status: goal.status,
                            savedAmount: goal.savedAmount,
                            targetAmount: goal.targetAmount,
                            progress: progress,
                            deadline: _formatDeadline(goal.deadline),
                            onDetails: () async {
                              // Abre el detalle de la meta y espera hasta regresar.
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GoalDetailScreen(goal: goal),
                                ),
                              );

                              // Recarga las metas desde SQLite para sincronizar
                              // la lista y la tarjeta de resumen.
                              await _loadGoals();
                            },
                            onContribute: () async {
                              final bool? contributionCreated =
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddContributionScreen(goal: goal),
                                    ),
                                  );

                              if (contributionCreated == true &&
                                  context.mounted) {
                                await _loadGoals();
                              }
                            },
                          );
                        }),

                      const SizedBox(height: 12),

                      // Botón principal para crear una nueva meta.
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // Abre el formulario para crear una nueva meta.
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddGoalScreen(),
                              ),
                            );

                            // Recarga las metas al regresar del formulario.
                            await _loadGoals();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Crear nueva meta',
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

                      const SizedBox(height: 24),

                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
