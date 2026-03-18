import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';

class MealsListScreen extends ConsumerStatefulWidget {
  const MealsListScreen({super.key});

  @override
  ConsumerState<MealsListScreen> createState() => _MealsListScreenState();
}

class _MealsListScreenState extends ConsumerState<MealsListScreen> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy · HH:mm', 'de_DE');

  List<dynamic> _meals = [];
  String? _error;
  bool _isLoading = true;
  String? _deletingId;
  int? _selectedSectionIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dogId = ref.read(selectedDogIdProvider);
    if (dogId == null) {
      setState(() {
        _error = 'Bitte zuerst einen Hund auswählen.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ref.read(apiClientProvider).dio.get('/dogs/$dogId/meals');
      setState(() {
        _meals = response.data as List<dynamic>;
        _error = null;
        _isLoading = false;
        _selectedSectionIndex = null;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?.toString() ?? 'Fehler beim Laden';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> meal) async {
    final id = meal['id'] as String?;
    if (id == null || _deletingId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mahlzeit entfernen?'),
        content: Text('Möchtest du die Mahlzeit von ${_formatDateTime(meal['eatenAt'])} wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = id);
    try {
      await ref.read(apiClientProvider).dio.delete('/meals/$id');
      setState(() {
        _meals.removeWhere((item) => (item as Map<String, dynamic>)['id'] == id);
        _deletingId = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mahlzeit wurde entfernt.')),
      );
    } on DioException catch (e) {
      setState(() => _deletingId = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?.toString() ?? 'Löschen fehlgeschlagen.')),
      );
    }
  }

  DateTime? _parseDateTime(dynamic rawValue) {
    if (rawValue is! String || rawValue.isEmpty) return null;
    return DateTime.tryParse(rawValue)?.toLocal();
  }

  String _formatDateTime(dynamic rawValue) {
    final date = _parseDateTime(rawValue);
    if (date == null) {
      return rawValue is String && rawValue.isNotEmpty ? rawValue : 'Unbekannte Zeit';
    }
    return _dateFormat.format(date);
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  _MealTotals _calculateTotals(List<Map<String, dynamic>> meals) {
    var kcal = 0.0;
    var protein = 0.0;
    var fat = 0.0;
    var crudeAsh = 0.0;
    var crudeFiber = 0.0;

    for (final meal in meals) {
      final entries = (meal['entries'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      for (final entry in entries) {
        final grams = _asDouble(entry['grams']);
        final factor = grams / 100;
        final food = entry['food'] as Map<String, dynamic>? ?? const <String, dynamic>{};
        kcal += factor * _asDouble(food['kcalPer100g']);
        protein += factor * _asDouble(food['proteinPercent']);
        fat += factor * _asDouble(food['fatPercent']);
        crudeAsh += factor * _asDouble(food['crudeAshPercent']);
        crudeFiber += factor * _asDouble(food['crudeFiberPercent']);
      }
    }

    return _MealTotals(
      kcal: kcal,
      protein: protein,
      fat: fat,
      crudeAsh: crudeAsh,
      crudeFiber: crudeFiber,
    );
  }

  String _mealTypeLabel(String? mealType) {
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
        return 'Mahlzeit';
    }
  }

  Widget _buildOverviewCard(List<Map<String, dynamic>> entries) {
    final mealsToday = entries.where((meal) {
      final eatenAt = _parseDateTime(meal['eatenAt']);
      return eatenAt != null && _isToday(eatenAt);
    }).toList();
    final totals = _calculateTotals(mealsToday);
    final sections = [
      _MacroSectionData(label: 'Protein', value: totals.protein, color: const Color(0xFF4FD49B)),
      _MacroSectionData(label: 'Fett', value: totals.fat, color: const Color(0xFFF4B860)),
      _MacroSectionData(label: 'Rohasche', value: totals.crudeAsh, color: const Color(0xFF7C8BFF)),
      _MacroSectionData(label: 'Rohfaser', value: totals.crudeFiber, color: const Color(0xFFE27DB4)),
    ];
    final totalMacros = sections.fold<double>(0, (sum, section) => sum + section.value);
    final selectedSection = _selectedSectionIndex != null && _selectedSectionIndex! < sections.length
        ? sections[_selectedSectionIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3FFFB), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142CB89D),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mahlzeiten heute',
            style: TextStyle(
              fontFamily: 'SourGummy',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF11332C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aufgenommene kcal heute mit Nährstoffverteilung aus Protein, Fett, Rohasche und Rohfaser.',
            style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 270,
                    height: 270,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD8F0E5)),
                  ),
                  Container(
                    width: 232,
                    height: 232,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2DB5B4)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          totals.kcal.round().toString(),
                          style: const TextStyle(
                            fontFamily: 'SourGummy',
                            fontSize: 42,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'kcal heute',
                          style: TextStyle(
                            fontFamily: 'RobotoCondensed',
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(width: 120, height: 1, color: Colors.white54),
                        const SizedBox(height: 8),
                        Text(
                          '${mealsToday.length} Mahlzeiten',
                          style: const TextStyle(
                            fontFamily: 'RobotoCondensed',
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 124,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            final touchedSection = response?.touchedSection;
                            if (!event.isInterestedForInteractions || touchedSection == null) {
                              if (_selectedSectionIndex != null) {
                                setState(() => _selectedSectionIndex = null);
                              }
                              return;
                            }

                            final index = touchedSection.touchedSectionIndex;
                            if (_selectedSectionIndex != index) {
                              setState(() => _selectedSectionIndex = index);
                            }
                          },
                        ),
                        sections: [
                          for (var i = 0; i < sections.length; i++)
                            PieChartSectionData(
                              value: sections[i].value <= 0 ? 0.0001 : sections[i].value,
                              color: sections[i].color,
                              radius: _selectedSectionIndex == i ? 42 : 34,
                              title: totalMacros > 0 && sections[i].value > 0
                                  ? '${((sections[i].value / totalMacros) * 100).round()}%'
                                  : '',
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < sections.length; i++)
                _buildLegendChip(
                  sections[i],
                  isSelected: _selectedSectionIndex == i,
                  percentage: totalMacros > 0 ? (sections[i].value / totalMacros) * 100 : 0,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FFFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x332CB89D)),
            ),
            child: selectedSection == null
                ? Text(
                    totalMacros > 0
                        ? 'Tippe auf einen Bereich im Kreisdiagramm, um Details zu sehen.'
                        : 'Heute wurden noch keine Nährwerte erfasst.',
                    style: TextStyle(color: Colors.blueGrey.shade700),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedSection.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF11332C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalMacros > 0
                            ? '${selectedSection.value.toStringAsFixed(1)} g · ${((selectedSection.value / totalMacros) * 100).toStringAsFixed(1)} % Anteil'
                            : '${selectedSection.value.toStringAsFixed(1)} g',
                        style: TextStyle(color: Colors.blueGrey.shade700),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip(_MacroSectionData section, {required bool isSelected, required double percentage}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? section.color.withOpacity(0.14) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: section.color.withOpacity(isSelected ? 0.6 : 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: section.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '${section.label}: ${section.value.toStringAsFixed(1)} g',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (percentage > 0) ...[
            const SizedBox(width: 6),
            Text('(${percentage.toStringAsFixed(0)} %)', style: TextStyle(color: Colors.blueGrey.shade700)),
          ],
        ],
      ),
    );
  }

  Widget _buildMealsList(List<Map<String, dynamic>> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Einträge',
          style: TextStyle(
            fontFamily: 'SourGummy',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF11332C),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Zum Entfernen einen Eintrag lange gedrückt halten.',
          style: TextStyle(color: Colors.blueGrey.shade700),
        ),
        const SizedBox(height: 12),
        ...entries.map((meal) {
          final id = meal['id'] as String?;
          final isDeleting = id != null && _deletingId == id;
          final mealEntries = (meal['entries'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          final totals = _calculateTotals([meal]);
          final mealType = mealEntries.isNotEmpty ? _mealTypeLabel(mealEntries.first['mealType'] as String?) : 'Mahlzeit';
          final foods = mealEntries
              .map((entry) => ((entry['food'] as Map<String, dynamic>?)?['name'] as String?) ?? 'Unbekanntes Futter')
              .join(', ');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onLongPress: isDeleting ? null : () => _confirmDelete(meal),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x1F2CB89D)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0x142CB89D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF2CB89D)),
                    ),
                    title: Text(
                      mealType,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_formatDateTime(meal['eatenAt'])),
                          const SizedBox(height: 4),
                          Text(
                            foods,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.blueGrey.shade700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${totals.kcal.toStringAsFixed(1)} kcal · Protein ${totals.protein.toStringAsFixed(1)} g · Fett ${totals.fat.toStringAsFixed(1)} g',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    trailing: isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.touch_app_outlined, color: Color(0xFF6F7F8C)),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _meals.cast<Map<String, dynamic>>();
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
            : entries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pie_chart_outline_rounded, size: 64, color: Colors.blueGrey.shade200),
                          const SizedBox(height: 12),
                          const Text(
                            'Noch keine Mahlzeiten vorhanden.',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erfasse die erste Mahlzeit über den Plus-Button, um hier die Tagesübersicht zu sehen.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.blueGrey.shade700),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      children: [
                        _buildOverviewCard(entries),
                        const SizedBox(height: 24),
                        _buildMealsList(entries),
                      ],
                    ),
                  );

    return AppShell(
      currentIndex: -1,
      title: 'Mahlzeiten',
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FBFC), Color(0xFFEFF7F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: content,
      ),
    );
  }
}

class _MealTotals {
  const _MealTotals({
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.crudeAsh,
    required this.crudeFiber,
  });

  final double kcal;
  final double protein;
  final double fat;
  final double crudeAsh;
  final double crudeFiber;
}

class _MacroSectionData {
  const _MacroSectionData({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}
