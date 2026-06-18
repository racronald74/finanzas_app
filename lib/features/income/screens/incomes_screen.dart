import 'package:flutter/material.dart';

import 'add_income_screen.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/income_provider.dart';

class IncomesScreen extends StatefulWidget {
  const IncomesScreen({super.key});

  @override
  State<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends State<IncomesScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final user = authProvider.currentUser;

      if (user != null) {
        Provider.of<IncomeProvider>(
          context,
          listen: false,
        ).loadIncomeData(user.idUsuario!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final incomeProvider = Provider.of<IncomeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ingresos')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // Ingreso fijo mensual
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),

                child: Column(
                  children: [
                    Text('Ingreso fijo mensual'),

                    SizedBox(height: 8),

                    // Monto del ingreso fijo mensual
                    Text(
                      '\$${Provider.of<AuthProvider>(context).currentUser?.ingresoFijoMensual.toStringAsFixed(0) ?? '0'}',

                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    // Botón para modificar ingreso fijo mensual
                    TextButton(
                      onPressed: () async {
                        final controller = TextEditingController();

                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );

                        controller.text =
                            authProvider.currentUser?.ingresoFijoMensual
                                .toString() ??
                            '0';

                        final resultado = await showDialog<double>(
                          context: context,

                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Ingreso fijo mensual'),

                              content: TextField(
                                controller: controller,

                                keyboardType: TextInputType.number,

                                decoration: const InputDecoration(
                                  labelText: 'Monto',
                                ),
                              ),

                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },

                                  child: const Text('Cancelar'),
                                ),

                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      context,

                                      double.tryParse(controller.text),
                                    );
                                  },

                                  child: const Text('Guardar'),
                                ),
                              ],
                            );
                          },
                        );

                        if (resultado == null) {
                          return;
                        }

                        await authProvider.updateFixedIncome(resultado);
                      },

                      child: const Text('Modificar'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            Text('Historial de ingresos adicionales'),

            SizedBox(height: 12),

            if (incomeProvider.additionalIncomes.isEmpty)
              const Card(
                child: ListTile(title: Text('Sin ingresos registrados')),
              )
            else
              ...incomeProvider.additionalIncomes.map((income) {
                return Card(
                  child: ListTile(
                    title: Text(
                      income.descripcion.isEmpty
                          ? 'Ingreso'
                          : income.descripcion,
                    ),

                    subtitle: Text(income.fecha.split('T').first),

                    trailing: Text('\$${income.monto.toStringAsFixed(0)}'),
                  ),
                );
              }),

            SizedBox(height: 24),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16),

                child: Column(
                  children: [
                    Text('Total ingresos del mes'),

                    SizedBox(height: 8),

                    Text(
                      '\$${((Provider.of<AuthProvider>(context).currentUser?.ingresoFijoMensual ?? 0) + incomeProvider.totalIncome).toStringAsFixed(0)}',

                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Botón para agregar nuevo ingreso adicional
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
          );

          if (!context.mounted) return;

          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );

          final user = authProvider.currentUser;

          if (user != null) {
            await Provider.of<IncomeProvider>(
              context,
              listen: false,
            ).loadIncomeData(user.idUsuario!);
          }
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}
