import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';

class RecipesListScreen extends ConsumerStatefulWidget {
  const RecipesListScreen({super.key});

  @override
  ConsumerState<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends ConsumerState<RecipesListScreen> {
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ref.read(apiClientProvider).dio.get('/recipes');
      setState(() {
        _recipes = (response.data as List<dynamic>).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?.toString() ?? 'Rezepte konnten nicht geladen werden.';
        _isLoading = false;
      });
    }
  }

  String _nutritionText(Map<String, dynamic> recipe) {
    final nutrition = recipe['nutrition'] as Map<String, dynamic>? ?? const {};
    final kcal = (nutrition['kcalTotal'] as num?)?.toStringAsFixed(0) ?? '0';
    final per100g = (nutrition['kcalPer100g'] as num?)?.toStringAsFixed(1) ?? '0.0';
    return '$kcal kcal gesamt · $per100g kcal / 100g';
  }

  String _portionText(Map<String, dynamic> recipe) {
    final portions = recipe['defaultPortions'] as num?;
    final gramsPerPortion = recipe['gramsPerPortion'] as num?;
    if (portions == null || gramsPerPortion == null) return 'Trackbar in Gramm';
    return '${portions.toStringAsFixed(portions % 1 == 0 ? 0 : 1)} Portionen · ${gramsPerPortion.toStringAsFixed(0)} g/Portion';
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 1,
      title: 'Rezepte',
      showQuickActionButton: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.pushNamed(context, '/recipes/create');
          if (created == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Rezept erstellen'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red)))])
                : _recipes.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Noch keine Rezepte vorhanden. Erstelle dein erstes Rezept für Snacks oder Hauptmahlzeiten.'),
                          )
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _recipes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final recipe = _recipes[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(recipe['title'] as String? ?? 'Ohne Titel', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((recipe['description'] as String?)?.isNotEmpty == true) Text(recipe['description'] as String),
                                    const SizedBox(height: 6),
                                    Text(_portionText(recipe)),
                                    Text(_nutritionText(recipe)),
                                  ],
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                final changed = await Navigator.pushNamed(context, '/recipes/detail', arguments: recipe['id']);
                                if (changed == true) _load();
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
