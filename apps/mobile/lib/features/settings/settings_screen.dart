import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';

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
                const Text('Account', style: TextStyle(fontFamily: 'SourGummy', fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Ausloggen'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Weitere Einstellungen folgen in einem nächsten Schritt.',
                  style: TextStyle(color: Color(0xFF6F7F8C)),
                ),
              ],
            ),
    );
  }
}
