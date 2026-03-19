import 'dart:math' as math;
import 'dart:async';

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
  String? _error;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    _duration.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
          TextField(
            controller: _search,
            focusNode: _searchFocusNode,
            decoration: const InputDecoration(
              labelText: 'Aktivität suchen',
              hintText: 'z. B. Spaziergang',
            ),
            onChanged: _onSearchChanged,
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: _searchResults
                    .map(
                      (activity) => ListTile(
                        title: Text(activity['name'] as String? ?? 'Aktivität'),
                        subtitle: Text('${_asDouble(activity['kcalPerMinute']).toStringAsFixed(2)} kcal/min für 10 kg'),
                        onTap: () => _selectActivity(activity),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (_notFound)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Keine Aktivität gefunden. Die Stammdaten werden in Directus durch die Administration gepflegt.'),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Dauer in Minuten'),
          ),
          const SizedBox(height: 16),
          if (_selectedActivity != null)
            _ActivityPreview(activity: _selectedActivity!, durationMinutes: duration),
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

class _ActivityPreview extends ConsumerWidget {
  const _ActivityPreview({required this.activity, required this.durationMinutes});

  final Map<String, dynamic> activity;
  final int durationMinutes;

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _weightForDog(Map<String, dynamic> dog) {
    final weights = (dog['weights'] as List<dynamic>? ?? const []);
    if (weights.isNotEmpty) {
      final latest = weights.first as Map<String, dynamic>;
      return _asDouble(latest['weightKg']);
    }
    return _asDouble(dog['targetWeightKg']) > 0 ? _asDouble(dog['targetWeightKg']) : 10;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Response<dynamic>>(
      future: () {
        final dogId = ref.read(selectedDogIdProvider);
        if (dogId == null) throw Exception('Kein Hund ausgewählt');
        return ref.read(apiClientProvider).dio.get('/dogs/$dogId');
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()));
        }
        final dog = (snapshot.data!.data as Map).cast<String, dynamic>();
        final weightKg = _weightForDog(dog);
        final ratio = weightKg > 0 ? (weightKg / 10) : 1.0;
        final multiplier = math.pow(ratio, 0.7).toDouble();
        final kcalPerMinute = _asDouble(activity['kcalPerMinute']);
        final total = kcalPerMinute * durationMinutes * multiplier;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['name'] as String? ?? 'Aktivität', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Referenzwert: ${kcalPerMinute.toStringAsFixed(2)} kcal/min für 10 kg'),
                Text('Hund: ${weightKg.toStringAsFixed(1)} kg'),
                Text('Multiplikator: ${multiplier.toStringAsFixed(2)}'),
                Text('Verbrauch: ${total.toStringAsFixed(1)} kcal für $durationMinutes min'),
              ],
            ),
          ),
        );
      },
    );
  }
}
