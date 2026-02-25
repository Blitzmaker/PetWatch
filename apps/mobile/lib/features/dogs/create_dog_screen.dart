import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_shell.dart';
import '../../core/providers.dart';
import 'breeds.dart';

class CreateDogScreen extends ConsumerStatefulWidget {
  const CreateDogScreen({super.key});

  @override
  ConsumerState<CreateDogScreen> createState() => _CreateDogScreenState();
}

class _CreateDogScreenState extends ConsumerState<CreateDogScreen> {
  final _name = TextEditingController();
  final _targetWeight = TextEditingController();
  final _currentWeight = TextEditingController();

  String? _sex = 'UNKNOWN';
  String? _activityLevel = 'MEDIUM';
  String? _breed;
  DateTime? _birthdate;
  String? _error;
  bool _loading = false;

  Future<void> _pickBirthdate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthdate = picked);
  }

  Future<void> _create() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider).dio;
      final dogResponse = await api.post('/dogs', data: {
        'name': _name.text.trim(),
        'breed': _breed,
        'birthdate': _birthdate?.toIso8601String(),
        'sex': _sex,
        'targetWeightKg': double.tryParse(_targetWeight.text),
        'activityLevel': _activityLevel,
      });

      final dogId = dogResponse.data['id'] as String;
      ref.read(selectedDogIdProvider.notifier).state = dogId;

      final currentWeight = double.tryParse(_currentWeight.text);
      if (currentWeight != null && currentWeight > 0) {
        await api.post('/dogs/$dogId/weights', data: {
          'date': DateTime.now().toIso8601String(),
          'weightKg': currentWeight,
        });
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Erstellen fehlgeschlagen');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 3,
      title: 'Hund anlegen',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            DropdownButtonFormField<String>(
              value: _breed,
              decoration: const InputDecoration(labelText: 'Rasse'),
              items: dogBreeds.map((breed) => DropdownMenuItem(value: breed, child: Text(breed))).toList(),
              onChanged: (value) => setState(() => _breed = value),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_birthdate == null ? 'Geburtsdatum wählen' : 'Geburtsdatum: ${_birthdate!.toIso8601String().split('T').first}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickBirthdate,
            ),
            DropdownButtonFormField<String>(
              value: _sex,
              decoration: const InputDecoration(labelText: 'Geschlecht'),
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Männlich')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Weiblich')),
                DropdownMenuItem(value: 'UNKNOWN', child: Text('Unbekannt')),
              ],
              onChanged: (value) => setState(() => _sex = value),
            ),
            DropdownButtonFormField<String>(
              value: _activityLevel,
              decoration: const InputDecoration(labelText: 'Aktivitätslevel'),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Niedrig')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Mittel')),
                DropdownMenuItem(value: 'HIGH', child: Text('Hoch')),
              ],
              onChanged: (value) => setState(() => _activityLevel = value),
            ),
            TextField(controller: _targetWeight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Zielgewicht (kg)')),
            TextField(controller: _currentWeight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Aktuelles Gewicht (kg, optional)')),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loading ? null : _create, child: Text(_loading ? 'Speichern...' : 'Speichern')),
          ],
        ),
      ),
    );
  }
}
