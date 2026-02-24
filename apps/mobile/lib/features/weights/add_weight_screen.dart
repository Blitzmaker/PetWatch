import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class AddWeightScreen extends ConsumerStatefulWidget {
  const AddWeightScreen({super.key});

  @override
  ConsumerState<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends ConsumerState<AddWeightScreen> {
  final _weight = TextEditingController();
  String? _error;

  Future<void> _save() async {
    final dogId = ref.read(selectedDogIdProvider);
    if (dogId == null) {
      setState(() => _error = 'Kein Hund ausgewählt');
      return;
    }
    try {
      await ref.read(apiClientProvider).dio.post('/dogs/$dogId/weights', data: {
        'date': DateTime.now().toIso8601String(),
        'weightKg': double.tryParse(_weight.text) ?? 0,
      });
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Speichern fehlgeschlagen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Weight')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gewicht in kg')),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }
}
