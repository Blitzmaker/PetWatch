import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';

class RecipeCreateScreen extends ConsumerStatefulWidget {
  const RecipeCreateScreen({super.key});

  @override
  ConsumerState<RecipeCreateScreen> createState() => _RecipeCreateScreenState();
}

class _RecipeCreateScreenState extends ConsumerState<RecipeCreateScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  final _yieldTotalGrams = TextEditingController();
  final _defaultPortions = TextEditingController();
  final _ingredientSearch = TextEditingController();
  final _ingredientGrams = TextEditingController(text: '100');
  final _stepController = TextEditingController();

  final _ingredientFocusNode = FocusNode();
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedFood;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _steps = [];
  String? _error;
  bool _isSaving = false;
  String? _recipeId;
  bool _initializedFromArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromArgs) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _recipeId = args['id'] as String?;
      _title.text = args['title'] as String? ?? '';
      _description.text = args['description'] as String? ?? '';
      _notes.text = args['notes'] as String? ?? '';
      _yieldTotalGrams.text = ((args['yieldTotalGrams'] as num?) ?? 0).toString();
      final portions = args['defaultPortions'] as num?;
      _defaultPortions.text = portions?.toString() ?? '';
      _items = ((args['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>()).map((item) {
        final food = item['food'] as Map<String, dynamic>? ?? const {};
        return {
          'foodId': item['foodId'],
          'grams': (item['grams'] as num?)?.toDouble() ?? 0,
          'food': food,
        };
      }).toList();
      _steps = ((args['steps'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>()).map((step) => {
        'title': step['title'],
        'instruction': step['instruction'],
      }).toList();
    }
    _initializedFromArgs = true;
  }

  Future<void> _searchFoods() async {
    final query = _ingredientSearch.text.trim();
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final response = await ref.read(apiClientProvider).dio.get('/foods/search', queryParameters: {'q': query});
      if (!mounted) return;
      setState(() => _searchResults = (response.data as List<dynamic>).cast<Map<String, dynamic>>());
    } on DioException {
      if (!mounted) return;
      setState(() => _searchResults = []);
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 150), _searchFoods);
  }

  void _addIngredient() {
    final food = _selectedFood;
    final grams = double.tryParse(_ingredientGrams.text.trim());
    if (food == null || grams == null || grams <= 0) {
      setState(() => _error = 'Bitte Food auswählen und gültige Gramm angeben.');
      return;
    }
    setState(() {
      _items.add({'foodId': food['id'], 'grams': grams, 'food': food});
      _selectedFood = null;
      _ingredientSearch.clear();
      _ingredientGrams.text = '100';
      _searchResults = [];
      _error = null;
      if (_yieldTotalGrams.text.trim().isEmpty) {
        _yieldTotalGrams.text = _items.fold<double>(0, (sum, item) => sum + ((item['grams'] as num?)?.toDouble() ?? 0)).toStringAsFixed(0);
      }
    });
  }

  void _addStep() {
    final instruction = _stepController.text.trim();
    if (instruction.isEmpty) return;
    setState(() {
      _steps.add({'instruction': instruction});
      _stepController.clear();
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final yieldTotalGrams = double.tryParse(_yieldTotalGrams.text.trim());
    final defaultPortions = _defaultPortions.text.trim().isEmpty ? null : double.tryParse(_defaultPortions.text.trim());
    if (title.isEmpty || yieldTotalGrams == null || yieldTotalGrams <= 0 || _items.isEmpty) {
      setState(() => _error = 'Bitte Titel, Gesamtgewicht und mindestens eine Zutat angeben.');
      return;
    }
    if (_defaultPortions.text.trim().isNotEmpty && (defaultPortions == null || defaultPortions <= 0)) {
      setState(() => _error = 'Portionen müssen größer als 0 sein.');
      return;
    }

    final payload = {
      'title': title,
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'yieldTotalGrams': yieldTotalGrams,
      'defaultPortions': defaultPortions,
      'items': _items.asMap().entries.map((entry) => {'foodId': entry.value['foodId'], 'grams': entry.value['grams'], 'sortOrder': entry.key}).toList(),
      'steps': _steps.asMap().entries.map((entry) => {'instruction': entry.value['instruction'], 'title': entry.value['title'], 'sortOrder': entry.key}).toList(),
    };

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (_recipeId == null) {
        await ref.read(apiClientProvider).dio.post('/recipes', data: payload);
      } else {
        await ref.read(apiClientProvider).dio.patch('/recipes/$_recipeId', data: payload);
      }
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?.toString() ?? 'Speichern fehlgeschlagen';
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    _yieldTotalGrams.dispose();
    _defaultPortions.dispose();
    _ingredientSearch.dispose();
    _ingredientGrams.dispose();
    _stepController.dispose();
    _ingredientFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: _recipeId == null ? 'Rezept erstellen' : 'Rezept bearbeiten',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Rezeptname')),
          TextField(controller: _description, decoration: const InputDecoration(labelText: 'Kurzbeschreibung (optional)')),
          TextField(controller: _yieldTotalGrams, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Gesamtgewicht in Gramm')),
          TextField(controller: _defaultPortions, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Standardportionen (optional)')),
          TextField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Hinweise (optional)')),
          const SizedBox(height: 16),
          const Text('Zutaten', style: TextStyle(fontWeight: FontWeight.bold)),
          RawAutocomplete<Map<String, dynamic>>(
            textEditingController: _ingredientSearch,
            focusNode: _ingredientFocusNode,
            optionsBuilder: (textEditingValue) {
              _onSearchChanged(textEditingValue.text);
              return _searchResults;
            },
            displayStringForOption: (option) => option['name'] as String? ?? '-',
            onSelected: (food) => setState(() => _selectedFood = food),
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(labelText: 'Food suchen'),
            ),
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250, minWidth: 260),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      for (final option in options)
                        ListTile(
                          title: Text(option['name'] as String? ?? '-'),
                          subtitle: Text(option['barcode'] as String? ?? '-'),
                          onTap: () => onSelected(option),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
          TextField(controller: _ingredientGrams, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Menge in Gramm')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _addIngredient, icon: const Icon(Icons.add), label: const Text('Zutat hinzufügen')),
          ..._items.asMap().entries.map((entry) {
            final item = entry.value;
            final food = item['food'] as Map<String, dynamic>? ?? const {};
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(food['name'] as String? ?? 'Food'),
              subtitle: Text('${((item['grams'] as num?) ?? 0).toStringAsFixed(0)} g'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _items.removeAt(entry.key)),
              ),
            );
          }),
          const Divider(height: 32),
          const Text('Zubereitungsschritte (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _stepController, maxLines: 3, decoration: const InputDecoration(labelText: 'Schrittbeschreibung')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _addStep, icon: const Icon(Icons.playlist_add), label: const Text('Schritt hinzufügen')),
          ..._steps.asMap().entries.map((entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Schritt ${entry.key + 1}'),
                subtitle: Text(entry.value['instruction'] as String? ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _steps.removeAt(entry.key)),
                ),
              )),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _isSaving ? null : _save, child: Text(_recipeId == null ? 'Rezept speichern' : 'Änderungen speichern')),
        ],
      ),
    );
  }
}
