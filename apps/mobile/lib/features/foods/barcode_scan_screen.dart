import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_shell.dart';
import '../../core/providers.dart';

class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final _barcode = TextEditingController();
  String? _message;

  Future<void> _lookup() async {
    final barcode = _barcode.text.trim();
    if (barcode.isEmpty) {
      setState(() => _message = 'Bitte einen Barcode eingeben.');
      return;
    }

    try {
      final response = await ref.read(apiClientProvider).dio.get('/foods/by-barcode/$barcode');
      final food = response.data as Map<String, dynamic>;
      if (!mounted) return;
      Navigator.pop(context, food);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final created = await Navigator.pushNamed(context, '/foods/create', arguments: barcode);
        if (!mounted) return;
        if (created is Map<String, dynamic>) {
          Navigator.pop(context, created);
          return;
        }
        setState(() => _message = 'Kein Treffer gefunden. Du kannst ein neues Futter anlegen.');
        return;
      }
      setState(() => _message = 'Fehler: ${e.response?.data ?? e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: 'Barcode scannen',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _barcode, decoration: const InputDecoration(labelText: 'Barcode')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _lookup, child: const Text('Suchen')),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!),
            ],
          ],
        ),
      ),
    );
  }
}
