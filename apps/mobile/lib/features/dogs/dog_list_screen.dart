import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class DogListScreen extends ConsumerStatefulWidget {
  const DogListScreen({super.key});

  @override
  ConsumerState<DogListScreen> createState() => _DogListScreenState();
}

class _DogListScreenState extends ConsumerState<DogListScreen> {
  List<dynamic> _dogs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    try {
      final response = await ref.read(apiClientProvider).dio.get('/dogs');
      setState(() {
        _dogs = response.data as List<dynamic>;
        _error = null;
      });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Fehler beim Laden');
    }
  }

  Future<void> _logout() async {
    final api = ref.read(apiClientProvider).dio;
    try {
      await api.post('/auth/logout');
    } catch (_) {}
    await ref.read(tokenStoreProvider).clear();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dogs'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDogs,
        child: _error != null
            ? ListView(children: [Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red)))])
            : ListView.builder(
                itemCount: _dogs.length,
                itemBuilder: (context, index) {
                  final dog = _dogs[index] as Map<String, dynamic>;
                  return ListTile(
                    title: Text(dog['name'] as String? ?? 'Ohne Name'),
                    subtitle: Text('ID: ${dog['id']}'),
                    onTap: () {
                      ref.read(selectedDogIdProvider.notifier).state = dog['id'] as String;
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Wrap(
                          children: [
                            ListTile(title: const Text('Gewichte'), onTap: () => Navigator.pushNamed(context, '/weights')),
                            ListTile(title: const Text('Mahlzeiten'), onTap: () => Navigator.pushNamed(context, '/meals')),
                            ListTile(title: const Text('Barcode Scan'), onTap: () => Navigator.pushNamed(context, '/scan')),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/dogs/create');
          _loadDogs();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
