import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class MealsListScreen extends ConsumerStatefulWidget {
  const MealsListScreen({super.key});

  @override
  ConsumerState<MealsListScreen> createState() => _MealsListScreenState();
}

class _MealsListScreenState extends ConsumerState<MealsListScreen> {
  List<dynamic> _meals = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dogId = ref.read(selectedDogIdProvider);
    if (dogId == null) {
      setState(() => _error = 'Bitte zuerst einen Hund auswählen.');
      return;
    }
    try {
      final response = await ref.read(apiClientProvider).dio.get('/dogs/$dogId/meals');
      setState(() {
        _meals = response.data as List<dynamic>;
        _error = null;
      });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Fehler beim Laden');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meals')),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                final meal = _meals[index] as Map<String, dynamic>;
                final entries = (meal['entries'] as List<dynamic>? ?? []).length;
                return ListTile(title: Text(meal['eatenAt'] as String? ?? ''), subtitle: Text('Einträge: $entries'));
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/meals/create');
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
