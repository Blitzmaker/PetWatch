import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_shell.dart';
import '../../core/providers.dart';

class FoodCreateScreen extends ConsumerStatefulWidget {
  const FoodCreateScreen({super.key});

  @override
  ConsumerState<FoodCreateScreen> createState() => _FoodCreateScreenState();
}

class _FoodCreateScreenState extends ConsumerState<FoodCreateScreen> {
  final _barcode = TextEditingController();
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _fat = TextEditingController();
  final _carbs = TextEditingController();
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialBarcode = ModalRoute.of(context)?.settings.arguments as String?;
    if (initialBarcode != null && _barcode.text.isEmpty) {
      _barcode.text = initialBarcode;
    }
  }

  Future<void> _create() async {
    try {
      final payload = {
        'barcode': _barcode.text.trim(),
        'name': _name.text.trim(),
        'kcalPer100g': int.tryParse(_kcal.text) ?? 1,
        'proteinPer100g': double.tryParse(_protein.text),
        'fatPer100g': double.tryParse(_fat.text),
        'carbsPer100g': double.tryParse(_carbs.text),
      };

      payload.removeWhere((_, value) => value == null);

      final response = await ref.read(apiClientProvider).dio.post('/foods', data: payload);
      if (mounted) Navigator.pop(context, response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Erstellen fehlgeschlagen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: 'Futter anlegen',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _barcode, decoration: const InputDecoration(labelText: 'Barcode')),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _kcal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'kcal / 100g')),
              TextField(controller: _protein, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein / 100g (optional)')),
              TextField(controller: _fat, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fett / 100g (optional)')),
              TextField(controller: _carbs, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kohlenhydrate / 100g (optional)')),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _create, child: const Text('Speichern')),
            ],
          ),
        ),
      ),
    );
  }
}
