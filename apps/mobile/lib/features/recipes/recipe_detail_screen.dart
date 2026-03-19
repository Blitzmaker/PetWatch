import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  Map<String, dynamic>? _recipe;
  String? _error;
  bool _isLoading = true;
  String? _recipeId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final recipeId = ModalRoute.of(context)?.settings.arguments as String?;
    if (recipeId != null && recipeId != _recipeId) {
      _recipeId = recipeId;
      _load();
    }
  }

  Future<void> _load() async {
    if (_recipeId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ref.read(apiClientProvider).dio.get('/recipes/$_recipeId');
      setState(() {
        _recipe = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?.toString() ?? 'Rezept konnte nicht geladen werden.';
        _isLoading = false;
      });
    }
  }

  Future<void> _delete() async {
    if (_recipeId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rezept löschen?'),
        content: const Text('Das Rezept wird entfernt, bereits getrackte Mahlzeiten bleiben erhalten.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(apiClientProvider).dio.delete('/recipes/$_recipeId');
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Löschen fehlgeschlagen');
    }
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red)));
    final recipe = _recipe;
    if (recipe == null) return const SizedBox.shrink();
    final items = (recipe['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final steps = (recipe['steps'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final nutrition = recipe['nutrition'] as Map<String, dynamic>? ?? const {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(recipe['title'] as String? ?? 'Rezept', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        if ((recipe['description'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(recipe['description'] as String),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gesamtmenge: ${((recipe['yieldTotalGrams'] as num?) ?? 0).toStringAsFixed(0)} g'),
                if (recipe['defaultPortions'] != null) Text('Portionen: ${(recipe['defaultPortions'] as num).toStringAsFixed((recipe['defaultPortions'] as num) % 1 == 0 ? 0 : 1)}'),
                if (recipe['gramsPerPortion'] != null) Text('Gramm pro Portion: ${((recipe['gramsPerPortion'] as num?) ?? 0).toStringAsFixed(0)} g'),
                const SizedBox(height: 8),
                Text('kcal gesamt: ${((nutrition['kcalTotal'] as num?) ?? 0).toStringAsFixed(1)}'),
                Text('kcal / 100g: ${((nutrition['kcalPer100g'] as num?) ?? 0).toStringAsFixed(1)}'),
                Text('Protein gesamt: ${((nutrition['proteinTotal'] as num?) ?? 0).toStringAsFixed(1)} g'),
                Text('Fett gesamt: ${((nutrition['fatTotal'] as num?) ?? 0).toStringAsFixed(1)} g'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Zutaten', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map((item) {
          final food = item['food'] as Map<String, dynamic>? ?? const {};
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(food['name'] as String? ?? 'Food'),
            subtitle: Text('${((item['grams'] as num?) ?? 0).toStringAsFixed(0)} g'),
          );
        }),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Zubereitung', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...steps.map((step) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(step['title'] as String? ?? 'Schritt'),
                subtitle: Text(step['instruction'] as String? ?? ''),
              )),
        ],
        if ((recipe['notes'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          const Text('Hinweise', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(recipe['notes'] as String),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/meals/create', arguments: {'mode': 'recipe', 'recipe': recipe}),
          icon: const Icon(Icons.restaurant),
          label: const Text('Dieses Rezept tracken'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final changed = await Navigator.pushNamed(context, '/recipes/create', arguments: recipe);
            if (changed == true) {
              await _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rezept aktualisiert.')));
              }
            }
          },
          icon: const Icon(Icons.edit),
          label: const Text('Bearbeiten'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline), label: const Text('Rezept löschen')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: 'Rezeptdetails',
      body: _buildBody(),
    );
  }
}
