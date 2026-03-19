import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_shell.dart';
import '../../core/providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _dog;
  List<dynamic> _weights = [];
  List<dynamic> _meals = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider).dio;
      final dogsResponse = await api.get('/dogs');
      final dogs = dogsResponse.data as List<dynamic>;

      if (dogs.isEmpty) {
        setState(() {
          _dog = null;
          _weights = [];
          _meals = [];
          _loading = false;
        });
        return;
      }

      final selectedDogId = ref.read(selectedDogIdProvider) ?? (dogs.first as Map<String, dynamic>)['id'] as String;
      ref.read(selectedDogIdProvider.notifier).state = selectedDogId;
      final currentDog = dogs.cast<Map<String, dynamic>>().firstWhere((dog) => dog['id'] == selectedDogId, orElse: () => dogs.first as Map<String, dynamic>);

      final responses = await Future.wait([
        api.get('/dogs/$selectedDogId/weights'),
        api.get('/dogs/$selectedDogId/meals'),
      ]);

      setState(() {
        _dog = currentDog;
        _weights = responses[0].data as List<dynamic>;
        _meals = responses[1].data as List<dynamic>;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?.toString() ?? 'Dashboard konnte nicht geladen werden.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return AppShell(
        currentIndex: 0,
        backgroundColor: const Color(0xFFBFE3D4),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    if (_dog == null) {
      return AppShell(
        currentIndex: 0,
        backgroundColor: const Color(0xFFBFE3D4),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Willkommen bei DogWatch', style: TextStyle(fontFamily: 'SourGummy', fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF1D7F6F))),
                const SizedBox(height: 16),
                const Text('Lege zuerst einen Hund an, um dein Dashboard zu sehen.'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/dogs/create');
                    _loadDashboard();
                  },
                  child: const Text('Hund anlegen'),
                )
              ],
            ),
          ),
        ),
      );
    }

    final latestWeight = _weights.isNotEmpty ? (_weights.first as Map<String, dynamic>)['weightKg'] as num : null;
    final targetWeight = _dog?['targetWeightKg'] as num?;
    final mealsTodayEntries = _meals.where((meal) {
      final eatenAt = DateTime.tryParse((meal as Map<String, dynamic>)['eatenAt'] as String? ?? '');
      if (eatenAt == null) return false;
      final now = DateTime.now();
      return eatenAt.year == now.year && eatenAt.month == now.month && eatenAt.day == now.day;
    }).toList();
    final mealsToday = mealsTodayEntries.length;

    final dailyKcalTarget = ((_dog?['dailyKcalTarget'] as num?)?.toDouble() ?? 700).clamp(1, 100000).toDouble();

    final consumedKcal = mealsTodayEntries.fold<double>(0, (sum, meal) {
      final entries = (meal as Map<String, dynamic>)['entries'] as List<dynamic>? ?? [];
      final mealKcal = entries.fold<double>(0, (entrySum, entry) {
        final map = entry as Map<String, dynamic>;
        final grams = (map['grams'] as num?)?.toDouble() ?? 0;
        final food = map['food'] as Map<String, dynamic>?;
        final kcal100 = (food?['kcalPer100g'] as num?)?.toDouble() ?? 0;
        return entrySum + ((grams / 100) * kcal100);
      });
      return sum + mealKcal;
    });

    final remainingKcal = (dailyKcalTarget - consumedKcal).clamp(0.0, dailyKcalTarget).toDouble();
    final progress = (consumedKcal / dailyKcalTarget).clamp(0, 1).toDouble();

    final lastWeighingText = _weights.isEmpty
        ? 'Noch nie'
        : _daysAgoText(DateTime.tryParse((_weights.first as Map<String, dynamic>)['date'] as String? ?? ''));

    return AppShell(
      currentIndex: 0,
      backgroundColor: const Color(0xFFBFE3D4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _HeaderCard(dogName: _dog?['name'] as String? ?? 'Hund', latestWeight: latestWeight?.toDouble(), targetWeight: targetWeight?.toDouble()),
              const SizedBox(height: 20),
              Center(child: _CalorieRing(remainingKcal: remainingKcal, targetKcal: dailyKcalTarget, progress: progress)),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Mahlzeiten\nheute',
                        value: '$mealsToday / 3',
                        icon: Icons.restaurant,
                        onTap: () => Navigator.pushNamed(context, '/meals'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(title: 'Aktivität\nheute', value: 'Niedrig', icon: Icons.pets)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: 'Letztes\nWiegen',
                        value: lastWeighingText,
                        icon: Icons.monitor_weight,
                        onTap: () => Navigator.pushNamed(context, '/weights'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  String _daysAgoText(DateTime? date) {
    if (date == null) return '0 / 3';
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Heute';
    if (days == 1) return 'Vor 1 Tag';
    return 'Vor $days Tagen';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.dogName, required this.latestWeight, required this.targetWeight});

  final String dogName;
  final double? latestWeight;
  final double? targetWeight;

  @override
  Widget build(BuildContext context) {
    final diff = (targetWeight != null && latestWeight != null) ? (targetWeight! - latestWeight!) : null;
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF7FCFB8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hallo $dogName!', style: const TextStyle(fontFamily: 'SourGummy', fontSize: 48 / 2, fontWeight: FontWeight.w700, color: Colors.white)),
                const CircleAvatar(radius: 36 / 2, backgroundColor: Colors.white, child: Text('🐶', style: TextStyle(fontSize: 22))),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF2F6F5), borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Aktuelles Gewicht', style: TextStyle(fontFamily: 'RobotoCondensed', color: Color(0xFF1F4E59), fontWeight: FontWeight.w700)),
                      Text(latestWeight == null ? '--' : '${latestWeight!.toStringAsFixed(1)} kg', style: const TextStyle(fontFamily: 'SourGummy', fontSize: 56 / 2, fontWeight: FontWeight.w700, color: Color(0xFF183D4C))),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFCDEEDC), borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Zielgewicht', style: TextStyle(fontFamily: 'RobotoCondensed', color: Color(0xFF2DA871), fontWeight: FontWeight.w700)),
                        Text(targetWeight == null ? '--' : '${targetWeight!.toStringAsFixed(1)} kg', style: const TextStyle(fontFamily: 'SourGummy', fontSize: 46 / 2, color: Color(0xFF22A06B), fontWeight: FontWeight.w700)),
                        Text(diff == null ? '--' : '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg', style: const TextStyle(fontFamily: 'SourGummy', color: Color(0xFF59A888), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({required this.remainingKcal, required this.targetKcal, required this.progress});

  final double remainingKcal;
  final double targetKcal;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 270, height: 270, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD8F0E5))),
          SizedBox(
            width: 258,
            height: 258,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF4FD49B)),
            ),
          ),
          Container(
            width: 232,
            height: 232,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2DB5B4)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(remainingKcal.round().toString(), style: const TextStyle(fontFamily: 'SourGummy', fontSize: 84 / 2, color: Colors.white, fontWeight: FontWeight.w700)),
                const Text('Kalorien übrig', style: TextStyle(fontFamily: 'RobotoCondensed', fontSize: 34 / 2, color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(width: 120, height: 1, color: Colors.white54),
                const SizedBox(height: 8),
                Text('Von ${targetKcal.round()} kcal', style: const TextStyle(fontFamily: 'RobotoCondensed', color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, this.onTap});

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 158,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF0F2F2), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 5, offset: Offset(0, 3))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontFamily: 'SourGummy', color: Color(0xFF1CB392), fontWeight: FontWeight.w600, fontSize: 15)),
            const Spacer(),
            Center(child: Icon(icon, color: const Color(0xFF2CB89D), size: 38)),
            const Spacer(),
            Center(child: Text(value, style: const TextStyle(fontFamily: 'RobotoCondensed', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF163847)))),
          ],
        ),
      ),
    );
  }
}
