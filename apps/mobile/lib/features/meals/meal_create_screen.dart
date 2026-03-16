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
  final _barcode = TextEditingController();
  final _grams = TextEditingController(text: '100');

  Map<String, dynamic>? _selectedFood;
  String? _error;
  late String _mealType;

  @override
  void initState() {
    super.initState();
    _mealType = _suggestMealTypeForLocalTime(DateTime.now());
  }

  String _suggestMealTypeForLocalTime(DateTime localDateTime) {
    final hour = localDateTime.hour;
    if (hour < 11) return 'BREAKFAST';
    if (hour <= 15) return 'LUNCH';
    return 'DINNER';
  }

  Future<void> _lookupBarcode() async {
    final barcode = _barcode.text.trim();
    if (barcode.isEmpty) {
      setState(() => _error = 'Bitte einen Barcode eingeben oder scannen.');
      return;
    }

    try {
      final response = await ref.read(apiClientProvider).dio.get('/foods/by-barcode/$barcode');
      setState(() {
        _selectedFood = response.data as Map<String, dynamic>;
        _error = null;
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        setState(() {
          _selectedFood = null;
          _error = 'Kein passendes Futter gefunden.';
        });
        return;
      }
      setState(() => _error = e.response?.data?.toString() ?? 'Barcode-Abgleich fehlgeschlagen');
    }
  }

  Future<void> _openFoodCreate() async {
    await Navigator.pushNamed(context, '/foods/create', arguments: _barcode.text.trim());
    if (_barcode.text.trim().isNotEmpty) {
      await _lookupBarcode();
    }
  }

  Future<void> _save() async {
    final dogId = ref.read(selectedDogIdProvider);
    if (dogId == null) {
      setState(() => _error = 'Kein Hund ausgewählt');
      return;
    }
    final selectedFoodId = _selectedFood?['id'] as String?;
    if (selectedFoodId == null) {
      setState(() => _error = 'Bitte zuerst ein Futter per Barcode auswählen.');
      return;
    }

    try {
      await ref.read(apiClientProvider).dio.post('/dogs/$dogId/meals', data: {
        'eatenAt': DateTime.now().toIso8601String(),
        'entries': [
          {'foodId': selectedFoodId, 'grams': double.tryParse(_grams.text) ?? 0, 'mealType': _mealType}
        ]
      });
      if (mounted) Navigator.pushReplacementNamed(context, '/meals');
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Speichern fehlgeschlagen');
    }
  }

  String _mealTypeLabel(String mealType) {
    switch (mealType) {
      case 'BREAKFAST':
        return 'Morgens';
      case 'LUNCH':
        return 'Mittags';
      case 'DINNER':
        return 'Abends';
      default:
        return mealType;
    }
  }

  Widget _buildNutrientsPreview() {
    if (_selectedFood == null) return const SizedBox.shrink();

    final grams = double.tryParse(_grams.text) ?? 0;
    final factor = grams / 100;

    final kcal = ((_selectedFood!['kcalPer100g'] as num?) ?? 0) * factor;
    final protein = ((_selectedFood!['proteinPer100g'] as num?) ?? 0) * factor;
    final fat = ((_selectedFood!['fatPer100g'] as num?) ?? 0) * factor;
    final carbs = ((_selectedFood!['carbsPer100g'] as num?) ?? 0) * factor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ausgewähltes Futter: ${_selectedFood!['name'] as String? ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Portion: ${grams.toStringAsFixed(0)} g'),
            Text('kcal: ${kcal.toStringAsFixed(1)}'),
            Text('Protein: ${protein.toStringAsFixed(1)} g'),
            Text('Fett: ${fat.toStringAsFixed(1)} g'),
            Text('Kohlenhydrate: ${carbs.toStringAsFixed(1)} g'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: 'Mahlzeit hinzufügen',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _barcode, decoration: const InputDecoration(labelText: 'Barcode eingeben oder scannen')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _lookupBarcode, child: const Text('Barcode abgleichen'))),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await Navigator.pushNamed(context, '/scan');
                      if (result is Map<String, dynamic>) {
                        setState(() {
                          _selectedFood = result;
                          _barcode.text = result['barcode'] as String? ?? _barcode.text;
                          _error = null;
                        });
                      }
                    },
                    child: const Text('Barcode scannen'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(onPressed: _openFoodCreate, child: const Text('Neues Futter anlegen')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mealType,
              items: const [
                DropdownMenuItem(value: 'BREAKFAST', child: Text('Morgens')),
                DropdownMenuItem(value: 'LUNCH', child: Text('Mittags')),
                DropdownMenuItem(value: 'DINNER', child: Text('Abends')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _mealType = value);
              },
              decoration: const InputDecoration(labelText: 'Tageszeit'),
            ),
            Text('Vorauswahl anhand lokaler Uhrzeit: ${_mealTypeLabel(_suggestMealTypeForLocalTime(DateTime.now()))}'),
            TextField(
              controller: _grams,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Portionsgröße (g)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _buildNutrientsPreview(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }
}
