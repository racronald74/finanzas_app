import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/income_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/income_provider.dart';
import 'add_income_screen.dart';

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
      _loadIncomeData();
    });
  }

  Future<void> _loadIncomeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    await Provider.of<IncomeProvider>(
      context,
      listen: false,
    ).loadIncomeData(user.idUsuario!);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final fixedIncome = authProvider.currentUser?.ingresoFijoMensual ?? 0;
    final monthlyTotal = fixedIncome + incomeProvider.totalIncome;

    return Scaffold(
      appBar: AppBar(title: const Text('Ingresos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Ingreso fijo mensual'),
                    const SizedBox(height: 8),
                    Text(
                      '\$${fixedIncome.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _editFixedIncome,
                      child: const Text('Modificar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Historial de ingresos adicionales'),
            const SizedBox(height: 12),
            if (incomeProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (incomeProvider.additionalIncomes.isEmpty)
              const Card(
                child: ListTile(title: Text('Sin ingresos registrados')),
              )
            else
              ...incomeProvider.additionalIncomes.map(_incomeTile),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Total ingresos del mes'),
                    const SizedBox(height: 8),
                    Text(
                      '\$${monthlyTotal.toStringAsFixed(0)}',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
          );

          if (!mounted) return;
          await _loadIncomeData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _incomeTile(IncomeModel income) {
    return Card(
      child: ListTile(
        title: Text(
          income.descripcion.isEmpty ? 'Ingreso' : income.descripcion,
        ),
        subtitle: Text(income.fecha.split('T').first),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\$${income.monto.toStringAsFixed(0)}'),
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddIncomeScreen(initialIncome: income),
                  ),
                );

                if (!mounted) return;
                await _loadIncomeData();
              },
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(income),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editFixedIncome() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final initialValue =
        authProvider.currentUser?.ingresoFijoMensual.toString() ?? '0';

    final result = await showDialog<double>(
      context: context,
      builder: (_) => _FixedIncomeDialog(initialValue: initialValue),
    );

    if (result == null) return;
    if (!mounted) return;

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final success = await authProvider.updateFixedIncome(result);

    if (!mounted) return;

    _showMessage(
      success ? 'Ingreso fijo actualizado' : 'No fue posible actualizar',
    );
  }

  Future<void> _confirmDelete(IncomeModel income) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar ingreso'),
          content: const Text('Esta accion no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    final success = await incomeProvider.deleteIncome(income);

    if (!mounted) return;

    _showMessage(success ? 'Ingreso eliminado' : 'No fue posible eliminar');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FixedIncomeDialog extends StatefulWidget {
  final String initialValue;

  const _FixedIncomeDialog({required this.initialValue});

  @override
  State<_FixedIncomeDialog> createState() => _FixedIncomeDialogState();
}

class _FixedIncomeDialogState extends State<_FixedIncomeDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ingreso fijo mensual'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: InputDecoration(labelText: 'Monto', errorText: _errorText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());

    if (value == null || value < 0) {
      setState(() {
        _errorText = 'Ingrese un monto valido';
      });
      return;
    }

    Navigator.pop(context, value);
  }
}
