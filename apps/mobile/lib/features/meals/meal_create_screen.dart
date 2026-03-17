import 'dart:async';

import 'package:dio/dio.dart';
import 'package:advanced_searchable_dropdown/advanced_searchable_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_shell.dart';
import '../../core/providers.dart';

class MealCreateScreen extends ConsumerStatefulWidget {
  const MealCreateScreen({super.key});

  @override
  ConsumerState<MealCreateScreen> createState() => _MealCreateScreenState();
}

class _MealCreateScreenState extends ConsumerState<MealCreateScreen> {
  final _search = TextEditingController();
  final _grams = TextEditingController(text: '100');

  Map<String, dynamic>? _selectedFood;
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasMoreResults = false;
  bool _notFound = false;
  Timer? _searchDebounce;
  int _latestSearchRequestId = 0;
  String? _error;
  late String _mealType;

  @override
  void initState() {
    super.initState();
    _mealType = _suggestMealTypeForLocalTime(DateTime.now());
  }

  String _suggestMealTypeForLocalTime(DateTime localDateTime) {
    final hour = localDateTime.hour;
    if (hour < 11) return 'BREAKFAST';
    if (hour <= 15) return 'LUNCH';
    return 'DINNER';
  }

  Future<void> _searchFoods() async {
    final requestId = ++_latestSearchRequestId;
    final query = _search.text.trim();
    if (query.isEmpty) {
      setState(() {
        _selectedFood = null;
        _searchResults = [];
        _hasMoreResults = false;
        _notFound = false;
        _error = null;
      });
      return;
    }

    try {
      final response = await ref.read(apiClientProvider).dio.get('/foods/search', queryParameters: {'q': query});

      if (!mounted || requestId != _latestSearchRequestId) return;

      final resultList = (response.data as List<dynamic>).cast<Map<String, dynamic>>();
      setState(() {
        _searchResults = resultList.take(5).toList();
        _hasMoreResults = resultList.length > 5;
        _notFound = resultList.isEmpty;
        final selectedFoodName = _selectedFood?['name'] as String?;
        final selectedFoodBarcode = _selectedFood?['barcode'] as String?;
        final searchTerm = _search.text.trim();
        if (selectedFoodName != searchTerm && selectedFoodBarcode != searchTerm) {
          _selectedFood = null;
        }
        _error = null;
      });
    } on DioException catch (e) {
      if (!mounted || requestId != _latestSearchRequestId) return;

      setState(() {
        _selectedFood = null;
        _searchResults = [];
        _hasMoreResults = false;
        _notFound = false;
        _error = e.response?.data?.toString() ?? 'Suche fehlgeschlagen';
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), _searchFoods);
  }

  void _selectFood(Map<String, dynamic> food) {
    setState(() {
      _selectedFood = food;
      _search.text = food['name'] as String? ?? (food['barcode'] as String? ?? '');
      _searchResults = [];
      _hasMoreResults = false;
      _notFound = false;
      _error = null;
    });
  }

  Future<void> _openScannerModal() async {
    final scannedBarcode = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _BarcodeScannerDialog(),
    );

    if (scannedBarcode == null || scannedBarcode.isEmpty) return;

    _search.text = scannedBarcode;
    await _searchFoods();
  }

  Future<void> _openFoodCreate() async {
    await Navigator.pushNamed(context, '/foods/create', arguments: _search.text.trim());
    if (_search.text.trim().isNotEmpty) {
      await _searchFoods();
    }
  }

  Future<void> _save() async {
    final dogId = ref.read(selectedDogIdProvider);
    if (dogId == null) {
      setState(() => _error = 'Kein Hund ausgewählt');
      return;
    }
    final selectedFoodId = _selectedFood?['id'] as String?;
    if (selectedFoodId == null) {
      setState(() => _error = 'Bitte zuerst ein Futter auswählen.');
      return;
    }

    try {
      await ref.read(apiClientProvider).dio.post('/dogs/$dogId/meals', data: {
        'eatenAt': DateTime.now().toIso8601String(),
        'entries': [
          {'foodId': selectedFoodId, 'grams': double.tryParse(_grams.text) ?? 0, 'mealType': _mealType}
        ]
      });
      if (mounted) Navigator.pushReplacementNamed(context, '/meals');
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Speichern fehlgeschlagen');
    }
  }

  String _mealTypeLabel(String mealType) {
    switch (mealType) {
      case 'BREAKFAST':
        return 'Morgens';
      case 'LUNCH':
        return 'Mittags';
      case 'DINNER':
        return 'Abends';
      default:
        return mealType;
    }
  }

  Widget _buildNutrientsPreview() {
    if (_selectedFood == null) return const SizedBox.shrink();

    final grams = double.tryParse(_grams.text) ?? 0;
    final factor = grams / 100;

    final kcal = ((_selectedFood!['kcalPer100g'] as num?) ?? 0) * factor;
    final protein = ((_selectedFood!['proteinPer100g'] as num?) ?? 0) * factor;
    final fat = ((_selectedFood!['fatPer100g'] as num?) ?? 0) * factor;
    final carbs = ((_selectedFood!['carbsPer100g'] as num?) ?? 0) * factor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ausgewähltes Futter: ${_selectedFood!['name'] as String? ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Portion: ${grams.toStringAsFixed(0)} g'),
            Text('kcal: ${kcal.toStringAsFixed(1)}'),
            Text('Protein: ${protein.toStringAsFixed(1)} g'),
            Text('Fett: ${fat.toStringAsFixed(1)} g'),
            Text('Kohlenhydrate: ${carbs.toStringAsFixed(1)} g'),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsDropdown() {
    if (_searchResults.isEmpty && !_hasMoreResults && !_notFound) return const SizedBox.shrink();

    if (_searchResults.isNotEmpty) {
      final dropdownItems = _searchResults
          .map(
            (food) => SearchableDropDownItem(
              label: '${food['name'] as String? ?? '-'} • ${food['barcode'] as String? ?? '-'}',
              value: food['id'] as String? ?? '',
            ),
          )
          .toList(growable: false);

      return SearchableDropDown(
        menuList: dropdownItems,
        value: _selectedFood?['id'] as String? ?? '',
        label: const Text('Nahrungsmittel auswählen'),
        hintText: 'Nahrungsmittel auswählen',
        onSelected: (item) {
          final food = _searchResults.firstWhere((result) => (result['id'] as String? ?? '') == item.value);
          _selectFood(food);
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (final food in _searchResults)
            ListTile(
              dense: true,
              title: Text(food['name'] as String? ?? '-'),
              subtitle: Text(food['barcode'] as String? ?? '-'),
              onTap: () => _selectFood(food),
            ),
          if (_notFound)
            const ListTile(
              dense: true,
              title: Text('Nahrungsmittel nicht gefunden.'),
              subtitle: Text('Bitte Suche verfeinern oder neues Futter anlegen.'),
            ),
          if (_hasMoreResults)
            const ListTile(
              dense: true,
              title: Text('... und weitere'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: 'Mahlzeit hinzufügen',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(labelText: 'Mahlzeit suchen:'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _openScannerModal,
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Barcode scannen',
                ),
              ],
            ),
            _buildSearchResultsDropdown(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(onPressed: _openFoodCreate, child: const Text('Neues Futter anlegen')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mealType,
              items: const [
                DropdownMenuItem(value: 'BREAKFAST', child: Text('Morgens')),
                DropdownMenuItem(value: 'LUNCH', child: Text('Mittags')),
                DropdownMenuItem(value: 'DINNER', child: Text('Abends')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _mealType = value);
              },
              decoration: const InputDecoration(labelText: 'Tageszeit'),
            ),
            Text('Vorauswahl anhand lokaler Uhrzeit: ${_mealTypeLabel(_suggestMealTypeForLocalTime(DateTime.now()))}'),
            TextField(
              controller: _grams,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Portionsgröße (g)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            _buildNutrientsPreview(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }
}

class _BarcodeScannerDialog extends StatefulWidget {
  const _BarcodeScannerDialog();

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final rawValue = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    final barcode = rawValue?.trim();
    if (barcode == null || barcode.isEmpty) return;

    _isProcessing = true;
    await _scannerController.stop();
    await HapticFeedback.lightImpact();

    if (mounted) {
      Navigator.pop(context, barcode);
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Barcode scannen', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 320,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
