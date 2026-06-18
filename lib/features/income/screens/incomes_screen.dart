import 'package:flutter/material.dart';

import 'add_income_screen.dart';

class IncomesScreen extends StatelessWidget {
  const IncomesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

                    Text(
                      '\$0',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    TextButton(onPressed: () {}, child: Text('Modificar')),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            Text('Historial de ingresos adicionales'),

            SizedBox(height: 12),

            Card(child: ListTile(title: Text('Sin ingresos registrados'))),

            SizedBox(height: 24),

            Card(
              child: Padding(
                padding: EdgeInsets.all(16),

                child: Column(
                  children: [
                    Text('Total ingresos del mes'),

                    SizedBox(height: 8),

                    Text(
                      '\$0',
                      style: TextStyle(
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
