import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider).dio;
      final store = ref.read(tokenStoreProvider);
      final response = await api.post('/auth/login', data: {'email': _email.text.trim(), 'password': _password.text});
      await store.saveTokens(response.data['accessToken'] as String, response.data['refreshToken'] as String);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Login fehlgeschlagen');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Passwort'), obscureText: true),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _loading ? null : _login, child: Text(_loading ? 'Lädt...' : 'Login')),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: const Text('Kein Konto? Registrieren')),
          ],
        ),
      ),
    );
  }
}
