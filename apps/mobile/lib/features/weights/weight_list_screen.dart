import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class WeightListScreen extends ConsumerStatefulWidget {
  const WeightListScreen({super.key});

  @override
  ConsumerState<WeightListScreen> createState() => _WeightListScreenState();
}

class _WeightListScreenState extends ConsumerState<WeightListScreen> {
  List<dynamic> _weights = [];
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
      final response = await ref.read(apiClientProvider).dio.get('/dogs/$dogId/weights');
      setState(() {
        _weights = response.data as List<dynamic>;
        _error = null;
      });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Fehler beim Laden');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weights')),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : ListView.builder(
              itemCount: _weights.length,
              itemBuilder: (context, index) {
                final entry = _weights[index] as Map<String, dynamic>;
                return ListTile(
                  title: Text('${entry['weightKg']} kg'),
                  subtitle: Text((entry['date'] as String?) ?? ''),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/weights/create');
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
