import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Login Screen'),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/dogs'), child: const Text('Weiter')),
        ]),
      ),
    );
  }
}
