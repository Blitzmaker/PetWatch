import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Register Screen'),
          ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Zum Login')),
        ]),
      ),
    );
  }
}
