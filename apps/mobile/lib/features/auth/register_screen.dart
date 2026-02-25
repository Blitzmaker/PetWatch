import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  Future<void> _register() async {
    setState(() => _error = null);
    try {
      final api = ref.read(apiClientProvider).dio;
      final store = ref.read(tokenStoreProvider);
      final response = await api.post('/auth/register', data: {'email': _email.text.trim(), 'password': _password.text});
      await store.saveTokens(response.data['accessToken'] as String, response.data['refreshToken'] as String);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?.toString() ?? 'Registrierung fehlgeschlagen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Passwort (min. 8)'), obscureText: true),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _register, child: const Text('Registrieren')),
          ],
        ),
      ),
    );
  }
}
