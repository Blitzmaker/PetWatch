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
  final _grams = TextEditingController(text: '100');
  Map<String, dynamic>? _selectedFood;
  String? _error;

  Future<void> _scanBarcode() async {
    final result = await Navigator.pushNamed(context, '/scan');
    if (!mounted) return;
    if (result is Map<String, dynamic>) {
      setState(() {
        _selectedFood = result;
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    final dogId = ref.read(selectedDogIdProvider);
    if (dogId == null) {
      setState(() => _error = 'Kein Hund ausgewählt');
      return;
    }
    final foodId = _selectedFood?['id'] as String?;
    if (foodId == null || foodId.isEmpty) {
      setState(() => _error = 'Bitte zuerst ein Futter per Barcode auswählen.');
      return;
    }

    try {
      await ref.read(apiClientProvider).dio.post('/dogs/$dogId/meals', data: {
        'eatenAt': DateTime.now().toIso8601String(),
        'entries': [
          {'foodId': foodId, 'grams': double.tryParse(_grams.text) ?? 0, 'mealType': 'DINNER'}
        ]
      });
      if (mounted) Navigator.pushReplacementNamed(context, '/meals');
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Speichern fehlgeschlagen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFoodName = _selectedFood?['name'] as String?;

    return AppShell(
      currentIndex: 1,
      title: 'Mahlzeit hinzufügen',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                title: Text(selectedFoodName ?? 'Kein Futter ausgewählt'),
                subtitle: Text(
                  _selectedFood == null
                      ? 'Scanne den Barcode, um ein Futter auszuwählen.'
                      : 'Barcode: ${_selectedFood?['barcode'] ?? '-'}',
                ),
                trailing: const Icon(Icons.qr_code_scanner),
                onTap: _scanBarcode,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _grams,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Gramm'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }
}
