import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class CreateDogScreen extends ConsumerStatefulWidget {
  const CreateDogScreen({super.key});

  @override
  ConsumerState<CreateDogScreen> createState() => _CreateDogScreenState();
}

class _CreateDogScreenState extends ConsumerState<CreateDogScreen> {
  final _name = TextEditingController();
  String? _error;

  Future<void> _create() async {
    try {
      await ref.read(apiClientProvider).dio.post('/dogs', data: {'name': _name.text.trim()});
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Erstellen fehlgeschlagen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Dog')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _create, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }
}
