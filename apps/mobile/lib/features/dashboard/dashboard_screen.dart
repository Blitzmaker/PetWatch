import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  static const double _dailyKcalTarget = 700;

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
      return Scaffold(
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    if (_dog == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFCFECE2),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text('Willkommen bei DogWatch', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF1D7F6F))),
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
        bottomNavigationBar: _BottomNav(currentIndex: 0),
      );
    }

    final latestWeight = _weights.isNotEmpty ? (_weights.first as Map<String, dynamic>)['weightKg'] as num : null;
    final targetWeight = _dog?['targetWeightKg'] as num?;
    final mealsToday = _meals.where((meal) {
      final eatenAt = DateTime.tryParse((meal as Map<String, dynamic>)['eatenAt'] as String? ?? '');
      if (eatenAt == null) return false;
      final now = DateTime.now();
      return eatenAt.year == now.year && eatenAt.month == now.month && eatenAt.day == now.day;
    }).length;

    final consumedKcal = _meals.fold<double>(0, (sum, meal) {
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

    final remainingKcal = (_dailyKcalTarget - consumedKcal).clamp(0, _dailyKcalTarget);
    final progress = (consumedKcal / _dailyKcalTarget).clamp(0, 1).toDouble();

    final lastWeighingText = _weights.isEmpty
        ? 'Noch nie'
        : _daysAgoText(DateTime.tryParse((_weights.first as Map<String, dynamic>)['date'] as String? ?? ''));

    return Scaffold(
      backgroundColor: const Color(0xFFBFE3D4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _HeaderCard(dogName: _dog?['name'] as String? ?? 'Hund', latestWeight: latestWeight?.toDouble(), targetWeight: targetWeight?.toDouble()),
              const SizedBox(height: 18),
              Center(
                child: _CalorieRing(remainingKcal: remainingKcal, targetKcal: _dailyKcalTarget, progress: progress),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(child: _StatCard(title: 'Mahlzeiten Heute', value: '$mealsToday / 3', icon: Icons.restaurant)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(title: 'Aktuelles Gewicht', value: latestWeight == null ? '--' : '${latestWeight.toStringAsFixed(1)} kg', icon: Icons.scale)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(title: 'Letztes Wiegen', value: lastWeighingText, icon: Icons.pets)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _ActionButton(
                      text: 'Mahlzeit hinzufügen',
                      icon: Icons.add,
                      filled: true,
                      onTap: () => Navigator.pushNamed(context, '/meals/create'),
                    ),
                    const SizedBox(height: 12),
                    _ActionButton(
                      text: 'Gewicht erfassen',
                      icon: Icons.pets,
                      filled: false,
                      onTap: () => Navigator.pushNamed(context, '/weights/create'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 0),
    );
  }

  String _daysAgoText(DateTime? date) {
    if (date == null) return 'Unbekannt';
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
    final up = latestWeight != null && targetWeight != null ? latestWeight! > targetWeight! : false;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF7DCCB1), Color(0xFF7BCAB7)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hallo $dogName!', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white)),
                const CircleAvatar(radius: 38, backgroundColor: Colors.white, child: Text('🐶', style: TextStyle(fontSize: 36))),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aktuelles Gewicht', style: TextStyle(fontSize: 20, color: Color(0xFF7B8A96), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        latestWeight == null ? '--' : '${latestWeight!.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: Color(0xFF1F4E59)),
                      ),
                      if (latestWeight != null && targetWeight != null)
                        Icon(up ? Icons.arrow_upward : Icons.arrow_downward, color: up ? const Color(0xFF30B886) : const Color(0xFF1D8FD0), size: 34),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFD2F1E4), borderRadius: BorderRadius.circular(14)),
                    child: Text(
                      targetWeight == null ? 'Kein Zielgewicht' : 'Ziel: ${targetWeight!.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2C9F72), fontSize: 22),
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
      width: 360,
      height: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 330,
            height: 330,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2F6EE)),
          ),
          SizedBox(
            width: 330,
            height: 330,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 22,
              backgroundColor: const Color(0xFFB9E9D9),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF59CF96)),
            ),
          ),
          Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF26B1B0), Color(0xFF22A7A8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 8))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(remainingKcal.round().toString(), style: const TextStyle(fontSize: 82, color: Colors.white, fontWeight: FontWeight.bold)),
                const Text('Kalorien übrig', style: TextStyle(fontSize: 52 / 2, color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(height: 1, width: 170, color: Colors.white.withOpacity(0.5)),
                const SizedBox(height: 10),
                Text('Von ${targetKcal.round()} kcal', style: const TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x20000000), blurRadius: 6, offset: Offset(0, 3))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF72828E), fontSize: 14)),
          const SizedBox(height: 8),
          Center(child: Icon(icon, size: 40, color: const Color(0xFF2DB79E))),
          const Spacer(),
          Container(height: 1, color: const Color(0xFFE3E8ED)),
          const SizedBox(height: 6),
          Center(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Color(0xFF2D4350))),
          )
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.text, required this.icon, required this.filled, required this.onTap});

  final String text;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = filled
        ? const LinearGradient(colors: [Color(0xFF54CE95), Color(0xFF25B9B6)])
        : const LinearGradient(colors: [Colors.white, Colors.white]);
    final textColor = filled ? Colors.white : const Color(0xFF6E808F);

    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          gradient: background,
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [BoxShadow(color: Color(0x20000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 32),
            const SizedBox(width: 12),
            Text(text, style: TextStyle(color: textColor, fontSize: 38 / 2, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFF2CB48F),
        unselectedItemColor: const Color(0xFF758795),
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/meals');
              break;
            case 2:
              Navigator.pushNamed(context, '/weights');
              break;
            case 3:
              Navigator.pushNamed(context, '/dogs');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Mahlzeiten'),
          BottomNavigationBarItem(icon: Icon(Icons.scale), label: 'Gewicht'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Profil'),
        ],
      ),
    );
  }
}
