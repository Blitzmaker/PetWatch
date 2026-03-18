import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';
import '../dogs/dog_calorie_helper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<dynamic> _dogs = const [];
  String? _selectedDogId;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ref.read(apiClientProvider).dio.get('/dogs');
      final dogs = response.data as List<dynamic>;
      final selectedDogId = ref.read(selectedDogIdProvider);
      setState(() {
        _dogs = dogs;
        _selectedDogId = dogs.any((d) => (d as Map<String, dynamic>)['id'] == selectedDogId)
            ? selectedDogId
            : (dogs.isNotEmpty ? (dogs.first as Map<String, dynamic>)['id'] as String : null);
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.data?.toString() ?? 'Einstellungen konnten nicht geladen werden.';
        _loading = false;
      });
    }
  }

  Future<void> _editKcalTarget(Map<String, dynamic> dog) async {
    final controller = TextEditingController(text: (dog['dailyKcalTarget'] as num?)?.round().toString() ?? '');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kalorienbedarf anpassen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              decoration: const InputDecoration(labelText: 'kcal pro Tag'),
            ),
            const SizedBox(height: 12),
            const Text(calorieCalculatorDisclaimer, style: TextStyle(color: Color(0xFF6F7F8C))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result == null || result <= 0) return;

    try {
      await ref.read(apiClientProvider).dio.patch('/dogs/${dog['id']}', data: {'dailyKcalTarget': result});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kalorienbedarf gespeichert.')));
      await _loadDogs();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.response?.data?.toString() ?? 'Kalorienbedarf konnte nicht gespeichert werden.')),
      );
    }
  }

  Future<void> _logout() async {
    final api = ref.read(apiClientProvider).dio;
    try {
      await api.post('/auth/logout');
    } catch (_) {}
    await ref.read(tokenStoreProvider).clear();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _saveDogSelection() {
    ref.read(selectedDogIdProvider.notifier).state = _selectedDogId;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aktiver Hund wurde gewechselt.')));
  }

  @override
  Widget build(BuildContext context) {
    final activeDog = _dogs.cast<Map<String, dynamic>?>().firstWhere(
          (dog) => dog?['id'] == _selectedDogId,
          orElse: () => _dogs.isNotEmpty ? _dogs.first as Map<String, dynamic> : null,
        );

    return AppShell(
      currentIndex: 3,
      title: 'Settings',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                ],
                const Text('Hund wechseln', style: TextStyle(fontFamily: 'SourGummy', fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDogId,
                  items: _dogs
                      .map(
                        (dog) => DropdownMenuItem<String>(
                          value: (dog as Map<String, dynamic>)['id'] as String,
                          child: Text(dog['name'] as String? ?? 'Ohne Name'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedDogId = value),
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Hund auswählen'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _selectedDogId == null ? null : _saveDogSelection, child: const Text('Hund aktivieren')),
                const SizedBox(height: 24),
                const Text('Kalorienbedarf', style: TextStyle(fontFamily: 'SourGummy', fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (activeDog != null)
                  Card(
                    child: ListTile(
                      title: Text('${activeDog['name']} · ${(activeDog['dailyKcalTarget'] as num?)?.round() ?? 0} kcal/Tag'),
                      subtitle: const Text(calorieCalculatorDisclaimer),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _editKcalTarget(activeDog),
                    ),
                  )
                else
                  const Text('Lege zuerst einen Hund an, um den Kalorienbedarf anzupassen.'),
                const SizedBox(height: 24),
                const Text('Account', style: TextStyle(fontFamily: 'SourGummy', fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Ausloggen'),
                ),
              ],
            ),
    );
  }
}
