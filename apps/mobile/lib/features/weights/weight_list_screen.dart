import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';

class WeightListScreen extends ConsumerStatefulWidget {
  const WeightListScreen({super.key});

  @override
  ConsumerState<WeightListScreen> createState() => _WeightListScreenState();
}

class _WeightListScreenState extends ConsumerState<WeightListScreen> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de_DE');

  List<dynamic> _weights = [];
  String? _error;
  bool _isLoading = true;
  String? _deletingId;

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
      final response = await ref.read(apiClientProvider).dio.get('/dogs/$dogId/weights');
      setState(() {
        _weights = response.data as List<dynamic>;
        _error = null;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?.toString() ?? 'Fehler beim Laden';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> entry) async {
    final id = entry['id'] as String?;
    if (id == null || _deletingId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eintrag entfernen?'),
        content: Text('Möchtest du den Gewichtseintrag vom ${_formatDate(entry['date'])} wirklich löschen?'),
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
      await ref.read(apiClientProvider).dio.delete('/weights/$id');
      setState(() {
        _weights.removeWhere((item) => (item as Map<String, dynamic>)['id'] == id);
        _deletingId = null;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gewichtseintrag wurde entfernt.')),
      );
    } on DioException catch (e) {
      setState(() => _deletingId = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?.toString() ?? 'Löschen fehlgeschlagen.')),
      );
    }
  }

  DateTime? _parseDate(dynamic rawValue) {
    if (rawValue is! String || rawValue.isEmpty) return null;
    return DateTime.tryParse(rawValue)?.toLocal();
  }

  String _formatDate(dynamic rawValue) {
    final date = _parseDate(rawValue);
    if (date == null) {
      return rawValue is String && rawValue.isNotEmpty ? rawValue : 'Unbekanntes Datum';
    }
    return _dateFormat.format(date);
  }

  double _weightValue(Map<String, dynamic> entry) {
    final value = entry['weightKg'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _buildChartCard(List<Map<String, dynamic>> entries) {
    final chartEntries = entries.take(10).toList().reversed.toList();
    final weights = chartEntries.map(_weightValue).toList();
    final minWeight = weights.reduce(math.min);
    final maxWeight = weights.reduce(math.max);
    final padding = math.max((maxWeight - minWeight) * 0.2, 0.5);
    final minY = math.max(0, minWeight - padding);
    final maxY = maxWeight + padding;

    final spots = <FlSpot>[
      for (var i = 0; i < chartEntries.length; i++) FlSpot(i.toDouble(), _weightValue(chartEntries[i])),
    ];

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
            'Letzte Wiegungen',
            style: TextStyle(
              fontFamily: 'SourGummy',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF11332C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bis zu 10 Einträge als Verlauf mit Gewicht auf der Y-Achse und Wiegungen auf der X-Achse.',
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (chartEntries.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: math.max(((maxY - minY) / 4), 0.5),
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0x1A2CB89D),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0x222CB89D)),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Gewicht (kg)', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    axisNameSize: 28,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: math.max(((maxY - minY) / 4), 0.5),
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text('Wiegungen', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    axisNameSize: 32,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 54,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= chartEntries.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 10,
                          child: Transform.rotate(
                            angle: -0.45,
                            child: Text(
                              _formatDate(chartEntries[index]['date']),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      final entry = chartEntries[spot.x.toInt()];
                      return LineTooltipItem(
                        '${_weightValue(entry).toStringAsFixed(1)} kg\n${_formatDate(entry['date'])}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF2CB89D),
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2CB89D).withOpacity(0.28),
                          const Color(0xFF2CB89D).withOpacity(0.02),
                        ],
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4.5,
                        color: Colors.white,
                        strokeColor: const Color(0xFF2CB89D),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightList(List<Map<String, dynamic>> entries) {
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
        ...entries.map((entry) {
          final id = entry['id'] as String?;
          final isDeleting = id != null && _deletingId == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onLongPress: isDeleting ? null : () => _confirmDelete(entry),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0x142CB89D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF2CB89D)),
                    ),
                    title: Text(
                      '${_weightValue(entry).toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_formatDate(entry['date'])),
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
    final entries = _weights.cast<Map<String, dynamic>>();
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
                          Icon(Icons.show_chart_rounded, size: 64, color: Colors.blueGrey.shade200),
                          const SizedBox(height: 12),
                          const Text(
                            'Noch keine Wiegungen vorhanden.',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erfasse das erste Gewicht über den Plus-Button, um hier einen Verlauf zu sehen.',
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
                        _buildChartCard(entries),
                        const SizedBox(height: 24),
                        _buildWeightList(entries),
                      ],
                    ),
                  );

    return AppShell(
      currentIndex: -1,
      title: 'Gewichte',
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
