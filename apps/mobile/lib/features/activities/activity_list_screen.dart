import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';

class ActivityListScreen extends ConsumerStatefulWidget {
  const ActivityListScreen({super.key});

  @override
  ConsumerState<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends ConsumerState<ActivityListScreen> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy · HH:mm', 'de_DE');

  List<dynamic> _activities = [];
  bool _isLoading = true;
  String? _error;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dogId = ref.read(selectedDogIdProvider);
    if (dogId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Bitte zuerst einen Hund auswählen.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ref.read(apiClientProvider).dio.get('/dogs/$dogId/activities');
      setState(() {
        _activities = response.data as List<dynamic>;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?.toString() ?? 'Aktivitäten konnten nicht geladen werden';
        _isLoading = false;
      });
    }
  }

  Future<void> _delete(Map<String, dynamic> entry) async {
    final id = entry['id'] as String?;
    if (id == null || _deletingId != null) return;
    setState(() => _deletingId = id);
    try {
      await ref.read(apiClientProvider).dio.delete('/activities/$id');
      setState(() {
        _activities.removeWhere((item) => (item as Map<String, dynamic>)['id'] == id);
        _deletingId = null;
      });
    } on DioException catch (e) {
      setState(() => _deletingId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.response?.data?.toString() ?? 'Löschen fehlgeschlagen')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _activities.cast<Map<String, dynamic>>();
    final today = entries.where((entry) {
      final performedAt = DateTime.tryParse(entry['performedAt'] as String? ?? '')?.toLocal();
      if (performedAt == null) return false;
      final now = DateTime.now();
      return performedAt.year == now.year && performedAt.month == now.month && performedAt.day == now.day;
    }).toList();
    final totalToday = today.fold<double>(0, (sum, entry) => sum + ((entry['kcalBurned'] as num?)?.toDouble() ?? 0));

    return AppShell(
      currentIndex: 2,
      title: 'Aktivitäten',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          title: const Text('Verbrauch heute'),
                          subtitle: Text('${today.length} Einträge'),
                          trailing: Text('${totalToday.toStringAsFixed(1)} kcal'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (entries.isEmpty)
                        const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Noch keine Aktivität erfasst.'))),
                      ...entries.map((entry) {
                        final activity = (entry['activity'] as Map<String, dynamic>? ?? const {});
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.directions_run),
                            title: Text(activity['name'] as String? ?? 'Aktivität'),
                            subtitle: Text('${_dateFormat.format(DateTime.parse(entry['performedAt'] as String).toLocal())} · ${entry['durationMinutes']} min · Faktor ${(entry['kcalMultiplier'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${(entry['kcalBurned'] as num?)?.toStringAsFixed(1) ?? '0.0'} kcal'),
                                TextButton(
                                  onPressed: _deletingId == entry['id'] ? null : () => _delete(entry),
                                  child: const Text('Löschen'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/activities/create').then((_) => _load()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
