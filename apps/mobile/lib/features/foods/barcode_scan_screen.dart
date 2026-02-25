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
    try {
      final response = await ref.read(apiClientProvider).dio.get('/foods/by-barcode/${_barcode.text.trim()}');
      setState(() => _message = 'Gefunden: ${response.data['name']}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        if (mounted) Navigator.pushNamed(context, '/foods/create', arguments: _barcode.text.trim());
        return;
      }
      setState(() => _message = 'Fehler: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: 'Barcode Lookup',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _barcode, decoration: const InputDecoration(labelText: 'Barcode')),
            ElevatedButton(onPressed: _lookup, child: const Text('Lookup')),
            if (_message != null) Text(_message!),
          ],
        ),
      ),
    );
  }
}
