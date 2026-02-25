import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_shell.dart';
import '../../core/providers.dart';

class MealCreateScreen extends ConsumerStatefulWidget {
  const MealCreateScreen({super.key});

  @override
  ConsumerState<MealCreateScreen> createState() => _MealCreateScreenState();
}

class _MealCreateScreenState extends ConsumerState<MealCreateScreen> {
  final _foodId = TextEditingController();
  final _grams = TextEditingController(text: '100');
  String? _error;

  Future<void> _save() async {
    final dogId = ref.read(selectedDogIdProvider);
    if (dogId == null) {
      setState(() => _error = 'Kein Hund ausgewählt');
      return;
    }
    try {
      await ref.read(apiClientProvider).dio.post('/dogs/$dogId/meals', data: {
        'eatenAt': DateTime.now().toIso8601String(),
        'entries': [
          {'foodId': _foodId.text.trim(), 'grams': double.tryParse(_grams.text) ?? 0, 'mealType': 'DINNER'}
        ]
      });
      if (mounted) Navigator.pushReplacementNamed(context, '/meals');
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Speichern fehlgeschlagen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: 'Mahlzeit hinzufügen',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _foodId, decoration: const InputDecoration(labelText: 'Food ID')),
            TextField(controller: _grams, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gramm')),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }
}
