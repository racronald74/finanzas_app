import 'package:flutter/material.dart';

import '../../../shared/widgets/app_header.dart';
import '../widgets/goal_overview_card.dart';
import '../widgets/goal_card.dart';

/// Pantalla principal del módulo Metas.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(title: 'Metas', showAvatar: true),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de resumen del módulo.
                  GoalOverviewCard(
                    totalSavings: 4250000,
                    activeGoals: 4,
                    totalProgress: 62,
                    monthlyGoal: 700000,
                    messageTitle: '¡Vas por buen camino!',
                    message:
                        'Estás \$150.000 por encima de tu objetivo mensual.',
                  ),

                  const SizedBox(height: 20),

                  // Título de la sección.
                  const Text(
                    'Mis metas',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  // Meta de ejemplo.
                  GoalCard(
                    icon: Icons.beach_access,
                    title: 'Vacaciones en familia',
                    description: 'Viaje a Cartagena en diciembre.',
                    status: 'Activa',
                    savedAmount: 1300000,
                    targetAmount: 2000000,
                    progress: 0.65,
                    deadline: '31/12/2026',
                    onDetails: () {},
                    onContribute: () {},
                  ),

                  // Segunda meta de ejemplo.
                  GoalCard(
                    icon: Icons.laptop_mac,
                    title: 'Nuevo portátil',
                    description: 'Comprar un portátil para estudiar.',
                    status: 'Activa',
                    savedAmount: 950000,
                    targetAmount: 3500000,
                    progress: 0.27,
                    deadline: '30/11/2026',
                    onDetails: () {},
                    onContribute: () {},
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
