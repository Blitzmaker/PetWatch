import 'package:dio/dio.dart';
import 'package:advanced_searchable_dropdown/advanced_searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';
import 'breeds.dart';
import 'dog_calorie_helper.dart';

class CreateDogScreen extends ConsumerStatefulWidget {
  const CreateDogScreen({super.key});

  @override
  ConsumerState<CreateDogScreen> createState() => _CreateDogScreenState();
}

class _CreateDogScreenState extends ConsumerState<CreateDogScreen> {
  final _name = TextEditingController();
  final _targetWeight = TextEditingController();
  final _currentWeight = TextEditingController();

  int _step = 0;
  String? _sex = 'UNKNOWN';
  String? _activityLevel = 'MEDIUM';
  String? _breed;
  DateTime? _birthdate;
  bool _isNeutered = false;
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

  double? get _currentWeightValue => double.tryParse(_currentWeight.text.replaceAll(',', '.'));
  double? get _targetWeightValue => double.tryParse(_targetWeight.text.replaceAll(',', '.'));

  double? get _calculatedKcal => calculateDogDailyKcal(
        currentWeightKg: _currentWeightValue,
        targetWeightKg: _targetWeightValue,
        birthdate: _birthdate,
        activityLevel: _activityLevel ?? 'MEDIUM',
        isNeutered: _isNeutered,
      );

  bool get _canGoToStepTwo => _name.text.trim().isNotEmpty && _birthdate != null;
  bool get _canSubmit => (_currentWeightValue != null && _currentWeightValue! > 0) || (_targetWeightValue != null && _targetWeightValue! > 0);

  Future<void> _create() async {
    if (!_canSubmit) {
      setState(() => _error = 'Bitte gib mindestens ein aktuelles oder Zielgewicht an.');
      return;
    }

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
        'targetWeightKg': _targetWeightValue,
        'activityLevel': _activityLevel,
        'isNeutered': _isNeutered,
        'dailyKcalTarget': _calculatedKcal?.round(),
        'currentWeightKg': _currentWeightValue,
      });

      final dogId = dogResponse.data['id'] as String;
      ref.read(selectedDogIdProvider.notifier).state = dogId;

      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Erstellen fehlgeschlagen');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _targetWeight.dispose();
    _currentWeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 0,
      title: 'Hund anlegen',
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0) {
            if (_canGoToStepTwo) {
              setState(() {
                _error = null;
                _step = 1;
              });
            } else {
              setState(() => _error = 'Bitte Name und Geburtsdatum ausfüllen.');
            }
            return;
          }
          _create();
        },
        onStepCancel: _step == 0 ? null : () => setState(() => _step = _step - 1),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _loading ? null : details.onStepContinue,
                  child: Text(_step == 0 ? 'Weiter' : (_loading ? 'Speichern...' : 'Hund anlegen')),
                ),
                if (_step > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(onPressed: _loading ? null : details.onStepCancel, child: const Text('Zurück')),
                ]
              ],
            ),
          );
        },
        steps: [
          Step(
            isActive: _step >= 0,
            title: const Text('Grunddaten'),
            content: Column(
              children: [
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                SearchableDropDown(
                  value: _breed,
                  hintText: 'Rasse',
                  decoration: const InputDecoration(labelText: 'Rasse'),
                  menuList: dogBreeds.map((breed) => SearchableDropDownItem(label: breed, value: breed)).toList(),
                  onSelected: (item) => setState(() => _breed = item.value as String),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_birthdate == null ? 'Geburtsdatum wählen' : 'Geburtsdatum: ${DateFormat('dd.MM.yyyy').format(_birthdate!)}'),
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
              ],
            ),
          ),
          Step(
            isActive: _step >= 1,
            title: const Text('Kalorienbedarf'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kastriert / sterilisiert'),
                  value: _isNeutered,
                  onChanged: (value) => setState(() => _isNeutered = value),
                ),
                TextField(controller: _currentWeight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Aktuelles Gewicht (kg)')),
                const SizedBox(height: 12),
                TextField(controller: _targetWeight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Zielgewicht (kg, optional)')),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8E6E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Empfohlene Tagesmenge', style: TextStyle(fontFamily: 'SourGummy', fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        _calculatedKcal == null ? 'Bitte Gewicht ergänzen, damit wir einen Richtwert berechnen können.' : '${_calculatedKcal!.round()} kcal pro Tag',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(calorieCalculatorDisclaimer, style: TextStyle(color: Color(0xFF6F7F8C))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _error == null
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
