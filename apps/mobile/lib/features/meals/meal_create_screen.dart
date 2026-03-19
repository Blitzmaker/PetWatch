import 'dart:async';

import 'package:dio/dio.dart';
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

enum _MealSourceMode { food, recipe }
enum _RecipeAmountMode { portions, grams }

class _MealCreateScreenState extends ConsumerState<MealCreateScreen> {
  final _search = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _grams = TextEditingController(text: '100');
  final _recipeAmount = TextEditingController(text: '1');

  Map<String, dynamic>? _selectedFood;
  Map<String, dynamic>? _selectedRecipe;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recipes = [];
  bool _hasMoreResults = false;
  bool _notFound = false;
  Timer? _searchDebounce;
  int _latestSearchRequestId = 0;
  String? _error;
  late String _mealType;
  _MealSourceMode _sourceMode = _MealSourceMode.food;
  _RecipeAmountMode _recipeAmountMode = _RecipeAmountMode.portions;

  @override
  void initState() {
    super.initState();
    _mealType = _suggestMealTypeForLocalTime(DateTime.now());
    _loadRecipes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['mode'] == 'recipe' && _selectedRecipe == null) {
      _sourceMode = _MealSourceMode.recipe;
      _selectedRecipe = (args['recipe'] as Map?)?.cast<String, dynamic>();
    }
  }

  String _suggestMealTypeForLocalTime(DateTime localDateTime) {
    final hour = localDateTime.hour;
    if (hour < 11) return 'BREAKFAST';
    if (hour <= 15) return 'LUNCH';
    return 'DINNER';
  }

  Future<void> _loadRecipes() async {
    try {
      final response = await ref.read(apiClientProvider).dio.get('/recipes');
      if (!mounted) return;
      setState(() => _recipes = (response.data as List<dynamic>).cast<Map<String, dynamic>>());
    } on DioException {
      // ignore non-blocking load failure here; surfaced when recipe mode is used
    }
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

    try {
      if (_sourceMode == _MealSourceMode.food) {
        final selectedFoodId = _selectedFood?['id'] as String?;
        if (selectedFoodId == null) {
          setState(() => _error = 'Bitte zuerst ein Futter auswählen.');
          return;
        }
        await ref.read(apiClientProvider).dio.post('/dogs/$dogId/meals', data: {
          'eatenAt': DateTime.now().toIso8601String(),
          'entries': [
            {'foodId': selectedFoodId, 'grams': double.tryParse(_grams.text) ?? 0, 'mealType': _mealType}
          ]
        });
      } else {
        final recipeId = _selectedRecipe?['id'] as String?;
        if (recipeId == null) {
          setState(() => _error = 'Bitte zuerst ein Rezept auswählen.');
          return;
        }
        final payload = {
          'recipeId': recipeId,
          'eatenAt': DateTime.now().toIso8601String(),
          'mealType': _mealType,
          'mode': _recipeAmountMode == _RecipeAmountMode.portions ? 'PORTIONS' : 'GRAMS',
          if (_recipeAmountMode == _RecipeAmountMode.portions) 'portions': double.tryParse(_recipeAmount.text) ?? 0,
          if (_recipeAmountMode == _RecipeAmountMode.grams) 'grams': double.tryParse(_recipeAmount.text) ?? 0,
        };
        await ref.read(apiClientProvider).dio.post('/dogs/$dogId/meals/from-recipe', data: payload);
      }
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
      case 'SNACK':
        return 'Snack';
      default:
        return mealType;
    }
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _buildFoodNutrientsPreview() {
    if (_selectedFood == null) return const SizedBox.shrink();

    final grams = double.tryParse(_grams.text) ?? 0;
    final factor = grams / 100;

    final kcal = ((_selectedFood!['kcalPer100g'] as num?) ?? 0) * factor;
    final protein = ((_selectedFood!['proteinPercent'] as num?) ?? 0) * factor;
    final fat = ((_selectedFood!['fatPercent'] as num?) ?? 0) * factor;
    final crudeAsh = ((_selectedFood!['crudeAshPercent'] as num?) ?? 0) * factor;
    final crudeFiber = ((_selectedFood!['crudeFiberPercent'] as num?) ?? 0) * factor;

    return _PreviewCard(
      title: 'Ausgewähltes Futter: ${_selectedFood!['name'] as String? ?? '-'}',
      lines: [
        'Portion: ${grams.toStringAsFixed(0)} g',
        'kcal: ${kcal.toStringAsFixed(1)}',
        'Protein: ${protein.toStringAsFixed(1)} g',
        'Fettgehalt: ${fat.toStringAsFixed(1)} g',
        'Rohasche: ${crudeAsh.toStringAsFixed(1)} g',
        'Rohfaser: ${crudeFiber.toStringAsFixed(1)} g',
      ],
    );
  }

  Widget _buildRecipePreview() {
    if (_selectedRecipe == null) return const SizedBox.shrink();
    final nutrition = _selectedRecipe!['nutrition'] as Map<String, dynamic>? ?? const {};
    final yieldTotalGrams = _asDouble(_selectedRecipe!['yieldTotalGrams']);
    final defaultPortions = _asDouble(_selectedRecipe!['defaultPortions']);
    final inputAmount = double.tryParse(_recipeAmount.text) ?? 0;
    final gramsTracked = _recipeAmountMode == _RecipeAmountMode.portions
        ? (defaultPortions > 0 ? inputAmount * (yieldTotalGrams / defaultPortions) : 0)
        : inputAmount;
    final scale = yieldTotalGrams > 0 ? gramsTracked / yieldTotalGrams : 0;

    return _PreviewCard(
      title: 'Ausgewähltes Rezept: ${_selectedRecipe!['title'] as String? ?? '-'}',
      lines: [
        if (defaultPortions > 0) 'Standardportionen: ${defaultPortions.toStringAsFixed(defaultPortions % 1 == 0 ? 0 : 1)}',
        'Geplante Menge: ${gramsTracked.toStringAsFixed(0)} g',
        if (_recipeAmountMode == _RecipeAmountMode.grams && defaultPortions > 0)
          '≈ ${(gramsTracked / (yieldTotalGrams / defaultPortions)).toStringAsFixed(2)} Portionen',
        'kcal: ${(_asDouble(nutrition['kcalTotal']) * scale).toStringAsFixed(1)}',
        'Protein: ${(_asDouble(nutrition['proteinTotal']) * scale).toStringAsFixed(1)} g',
        'Fett: ${(_asDouble(nutrition['fatTotal']) * scale).toStringAsFixed(1)} g',
      ],
    );
  }

  Widget _buildSourceSwitcher() {
    return SegmentedButton<_MealSourceMode>(
      segments: const [
        ButtonSegment(value: _MealSourceMode.food, label: Text('Food'), icon: Icon(Icons.set_meal)),
        ButtonSegment(value: _MealSourceMode.recipe, label: Text('Rezept'), icon: Icon(Icons.menu_book)),
      ],
      selected: {_sourceMode},
      onSelectionChanged: (selection) {
        setState(() {
          _sourceMode = selection.first;
          _error = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    _searchFocusNode.dispose();
    _grams.dispose();
    _recipeAmount.dispose();
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
            _buildSourceSwitcher(),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mealType,
              items: const [
                DropdownMenuItem(value: 'BREAKFAST', child: Text('Morgens')),
                DropdownMenuItem(value: 'LUNCH', child: Text('Mittags')),
                DropdownMenuItem(value: 'DINNER', child: Text('Abends')),
                DropdownMenuItem(value: 'SNACK', child: Text('Snack')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _mealType = value);
              },
              decoration: const InputDecoration(labelText: 'Tageszeit'),
            ),
            Text('Vorauswahl anhand lokaler Uhrzeit: ${_mealTypeLabel(_suggestMealTypeForLocalTime(DateTime.now()))}'),
            const SizedBox(height: 12),
            if (_sourceMode == _MealSourceMode.food) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RawAutocomplete<Map<String, dynamic>>(
                      textEditingController: _search,
                      focusNode: _searchFocusNode,
                      optionsBuilder: (textEditingValue) {
                        _onSearchChanged(textEditingValue.text);
                        final query = textEditingValue.text.trim();
                        if (query.isEmpty) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return _searchResults;
                      },
                      displayStringForOption: (food) => food['name'] as String? ?? '-',
                      onSelected: _selectFood,
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: 'Food suchen'),
                          onSubmitted: (_) => onFieldSubmitted(),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280, minWidth: 260),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: [
                                  for (final option in options)
                                    ListTile(
                                      dense: true,
                                      title: Text(option['name'] as String? ?? '-'),
                                      subtitle: Text(option['barcode'] as String? ?? '-'),
                                      onTap: () => onSelected(option),
                                    ),
                                  if (_notFound)
                                    const ListTile(
                                      dense: true,
                                      title: Text('Nahrungsmittel nicht gefunden.'),
                                      subtitle: Text('Bitte Suche verfeinern oder neues Futter anlegen.'),
                                    ),
                                  if (_hasMoreResults)
                                    const ListTile(dense: true, title: Text('... und weitere')),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _openScannerModal, icon: const Icon(Icons.camera_alt), tooltip: 'Barcode scannen'),
                ],
              ),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: OutlinedButton(onPressed: _openFoodCreate, child: const Text('Neues Futter anlegen'))),
              TextField(
                controller: _grams,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Portionsgröße (g)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _buildFoodNutrientsPreview(),
            ] else ...[
              if (_recipes.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Noch keine Rezepte geladen. Lege zuerst ein Rezept an.'),
                ),
              DropdownButtonFormField<String>(
                value: (() {
                  final selectedRecipeId = _selectedRecipe?['id'] as String?;
                  if (selectedRecipeId == null) return null;
                  return _recipes.any((recipe) => recipe['id'] == selectedRecipeId) ? selectedRecipeId : null;
                })(),
                items: _recipes
                    .map((recipe) => DropdownMenuItem<String>(
                          value: recipe['id'] as String,
                          child: Text(recipe['title'] as String? ?? 'Rezept'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedRecipe = _recipes.firstWhere((recipe) => recipe['id'] == value));
                },
                decoration: const InputDecoration(labelText: 'Rezept auswählen'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Portionen'),
                    selected: _recipeAmountMode == _RecipeAmountMode.portions,
                    onSelected: (_) => setState(() {
                      _recipeAmountMode = _RecipeAmountMode.portions;
                      _recipeAmount.text = '1';
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('Gramm'),
                    selected: _recipeAmountMode == _RecipeAmountMode.grams,
                    onSelected: (_) => setState(() {
                      _recipeAmountMode = _RecipeAmountMode.grams;
                      _recipeAmount.text = ((_selectedRecipe?['gramsPerPortion'] as num?) ?? 100).toStringAsFixed(0);
                    }),
                  ),
                ],
              ),
              TextField(
                controller: _recipeAmount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: _recipeAmountMode == _RecipeAmountMode.portions ? 'Portionen' : 'Gramm'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final created = await Navigator.pushNamed(context, '/recipes');
                    if (created == true) await _loadRecipes();
                  },
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Rezepte verwalten'),
                ),
              ),
              const SizedBox(height: 12),
              _buildRecipePreview(),
            ],
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            for (final line in lines) Text(line),
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
