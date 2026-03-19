import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';

class AddActivityScreen extends ConsumerStatefulWidget {
  const AddActivityScreen({super.key});

  @override
  ConsumerState<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends ConsumerState<AddActivityScreen> {
  final _search = TextEditingController();
  final _duration = TextEditingController(text: '30');
  final _searchFocusNode = FocusNode();
  final _performedAt = DateTime.now();

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedActivity;
  Timer? _searchDebounce;
  int _latestSearchRequestId = 0;
  bool _isSaving = false;
  bool _notFound = false;
  bool _hasLoadedDog = false;
  double _dogWeightKg = 10;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDogWeight();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    _duration.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDogWeight() async {
    final dogId = ref.read(selectedDogIdProvider);
    if (dogId == null) {
      if (mounted) {
        setState(() {
          _dogWeightKg = 10;
          _hasLoadedDog = true;
        });
      }
      return;
    }

    try {
      final response = await ref.read(apiClientProvider).dio.get('/dogs/$dogId');
      if (!mounted) return;
      final dog = (response.data as Map).cast<String, dynamic>();
      setState(() {
        _dogWeightKg = _weightForDog(dog);
        _hasLoadedDog = true;
      });
    } on DioException {
      if (!mounted) return;
      setState(() {
        _dogWeightKg = 10;
        _hasLoadedDog = true;
      });
    }
  }

  Future<void> _searchActivities() async {
    final requestId = ++_latestSearchRequestId;
    final query = _search.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _selectedActivity = null;
        _notFound = false;
        _error = null;
      });
      return;
    }

    try {
      final response = await ref.read(apiClientProvider).dio.get('/activities/search', queryParameters: {'q': query});
      if (!mounted || requestId != _latestSearchRequestId) return;
      final results = (response.data as List<dynamic>).cast<Map<String, dynamic>>();
      setState(() {
        _searchResults = results.take(5).toList();
        _notFound = results.isEmpty;
        if (_selectedActivity?['name'] != _search.text.trim()) {
          _selectedActivity = null;
        }
        _error = null;
      });
    } on DioException catch (e) {
      if (!mounted || requestId != _latestSearchRequestId) return;
      setState(() {
        _searchResults = [];
        _selectedActivity = null;
        _notFound = false;
        _error = e.response?.data?.toString() ?? 'Aktivitäten konnten nicht geladen werden';
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), _searchActivities);
  }

  void _selectActivity(Map<String, dynamic> activity) {
    setState(() {
      _selectedActivity = activity;
      _search.text = activity['name'] as String? ?? '';
      _searchResults = [];
      _notFound = false;
      _error = null;
    });
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _weightForDog(Map<String, dynamic> dog) {
    final weights = (dog['weights'] as List<dynamic>? ?? const []);
    if (weights.isNotEmpty) {
      final latest = weights.first as Map<String, dynamic>;
      final latestWeight = _asDouble(latest['weightKg']);
      if (latestWeight > 0) return latestWeight;
    }

    final targetWeight = _asDouble(dog['targetWeightKg']);
    return targetWeight > 0 ? targetWeight : 10;
  }

  double _activityMultiplier() {
    final ratio = _dogWeightKg > 0 ? (_dogWeightKg / 10) : 1.0;
    return math.pow(ratio, 0.7).toDouble();
  }

  double _adjustedKcalPerMinute(Map<String, dynamic> activity) {
    return _asDouble(activity['kcalPerMinute']) * _activityMultiplier();
  }

  Future<void> _save() async {
    final dogId = ref.read(selectedDogIdProvider);
    if (dogId == null) {
      setState(() => _error = 'Kein Hund ausgewählt');
      return;
    }

    final activityId = _selectedActivity?['id'] as String?;
    final duration = int.tryParse(_duration.text.trim());
    if (activityId == null) {
      setState(() => _error = 'Bitte zuerst eine Aktivität auswählen.');
      return;
    }
    if (duration == null || duration <= 0) {
      setState(() => _error = 'Bitte eine gültige Dauer in Minuten angeben.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(apiClientProvider).dio.post('/dogs/$dogId/activities', data: {
        'activityId': activityId,
        'durationMinutes': duration,
        'performedAt': _performedAt.toIso8601String(),
      });
      if (mounted) Navigator.pushReplacementNamed(context, '/activities');
    } on DioException catch (e) {
      setState(() {
        _isSaving = false;
        _error = e.response?.data?.toString() ?? 'Speichern fehlgeschlagen';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = int.tryParse(_duration.text.trim()) ?? 0;

    return AppShell(
      currentIndex: 2,
      title: 'Aktivität erfassen',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RawAutocomplete<Map<String, dynamic>>(
            textEditingController: _search,
            focusNode: _searchFocusNode,
            optionsBuilder: (textEditingValue) {
              _onSearchChanged(textEditingValue.text);
              final query = textEditingValue.text.trim();
              if (query.isEmpty) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              return _searchResults;
            },
            displayStringForOption: (activity) => activity['name'] as String? ?? '-',
            onSelected: _selectActivity,
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Aktivität suchen',
                  hintText: 'z. B. Spaziergang',
                ),
                onSubmitted: (_) => onFieldSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280, minWidth: 260),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        for (final option in options)
                          ListTile(
                            dense: true,
                            title: Text(option['name'] as String? ?? '-'),
                            subtitle: Text('${_adjustedKcalPerMinute(option).toStringAsFixed(2)} kcal/min bei ${_dogWeightKg.toStringAsFixed(1)} kg'),
                            onTap: () => onSelected(option),
                          ),
                        if (_notFound)
                          const ListTile(
                            dense: true,
                            title: Text('Keine Aktivität gefunden.'),
                            subtitle: Text('Die Aktivitätsliste wird in Directus durch die Administration gepflegt.'),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          if (_hasLoadedDog)
            Text(
              'Berechnung für ${_dogWeightKg.toStringAsFixed(1)} kg Körpergewicht.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Dauer in Minuten'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_selectedActivity != null)
            _ActivityPreview(
              activity: _selectedActivity!,
              durationMinutes: duration,
              dogWeightKg: _dogWeightKg,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? 'Speichern…' : 'Speichern'),
          ),
          const SizedBox(height: 8),
          Text(
            'Die Berechnung erfolgt automatisch anhand des zuletzt erfassten Gewichts des Hundes mit der Formel kcal/min × (Gewicht/10)^0,7.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ActivityPreview extends StatelessWidget {
  const _ActivityPreview({
    required this.activity,
    required this.durationMinutes,
    required this.dogWeightKg,
  });

  final Map<String, dynamic> activity;
  final int durationMinutes;
  final double dogWeightKg;

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = dogWeightKg > 0 ? (dogWeightKg / 10) : 1.0;
    final multiplier = math.pow(ratio, 0.7).toDouble();
    final referenceKcalPerMinute = _asDouble(activity['kcalPerMinute']);
    final adjustedKcalPerMinute = referenceKcalPerMinute * multiplier;
    final total = adjustedKcalPerMinute * durationMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity['name'] as String? ?? 'Aktivität',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Referenzwert: ${referenceKcalPerMinute.toStringAsFixed(2)} kcal/min für 10 kg',
            ),
            Text('Hund: ${dogWeightKg.toStringAsFixed(1)} kg'),
            Text('Multiplikator: ${multiplier.toStringAsFixed(2)}'),
            Text(
              'Umgerechnet: ${adjustedKcalPerMinute.toStringAsFixed(2)} kcal/min',
            ),
            Text(
              'Verbrauch: ${total.toStringAsFixed(1)} kcal für $durationMinutes min',
            ),
          ],
        ),
      ),
    );
  }
}
