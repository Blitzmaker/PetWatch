import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_shell.dart';
import '../../core/providers.dart';

class FoodCreateScreen extends ConsumerStatefulWidget {
  const FoodCreateScreen({super.key});

  @override
  ConsumerState<FoodCreateScreen> createState() => _FoodCreateScreenState();
}

class _FoodCreateScreenState extends ConsumerState<FoodCreateScreen> {
  final _barcode = TextEditingController();
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _fat = TextEditingController();
  final _crudeAsh = TextEditingController();
  final _crudeFiber = TextEditingController();
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialBarcode = ModalRoute.of(context)?.settings.arguments as String?;
    if (initialBarcode != null && _barcode.text.isEmpty) {
      _barcode.text = initialBarcode;
    }
  }

  double? _parsePercent(TextEditingController controller, String label) {
    final value = controller.text.trim();
    if (value.isEmpty) return null;

    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0 || parsed > 100) {
      throw FormatException('$label muss zwischen 0 und 100 liegen.');
    }

    return parsed;
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Bitte Namen des Futters angeben.');
      return;
    }

    final kcal = int.tryParse(_kcal.text.trim());
    if (kcal == null || kcal <= 0) {
      setState(() => _error = 'Bitte gültige kcal pro 100g angeben.');
      return;
    }

    try {
      await ref.read(apiClientProvider).dio.post('/foods', data: {
        'barcode': _barcode.text.trim(),
        'name': name,
        'kcalPer100g': kcal,
        'proteinPercent': _parsePercent(_protein, 'Protein'),
        'fatPercent': _parsePercent(_fat, 'Fettgehalt'),
        'crudeAshPercent': _parsePercent(_crudeAsh, 'Rohasche'),
        'crudeFiberPercent': _parsePercent(_crudeFiber, 'Rohfaser'),
      });
      if (mounted) Navigator.pop(context, true);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Erstellen fehlgeschlagen');
    }
  }

  @override
  void dispose() {
    _barcode.dispose();
    _name.dispose();
    _kcal.dispose();
    _protein.dispose();
    _fat.dispose();
    _crudeAsh.dispose();
    _crudeFiber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: 'Futter anlegen',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Wenn kein Treffer gefunden wurde, kannst du hier ein neues Futter zur Prüfung anlegen.'),
            TextField(controller: _barcode, decoration: const InputDecoration(labelText: 'Barcode')),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name des Futters')),
            TextField(controller: _kcal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'kcal / 100g')),
            TextField(controller: _protein, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Protein (%) pro 100g')),
            TextField(controller: _fat, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Fettgehalt (%) pro 100g')),
            TextField(controller: _crudeAsh, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Rohasche (%) pro 100g')),
            TextField(controller: _crudeFiber, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Rohfaser (%) pro 100g')),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _create, child: const Text('Speichern und zur Prüfung einreichen')),
          ],
        ),
      ),
    );
  }
}
