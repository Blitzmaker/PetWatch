import 'package:flutter/material.dart';

class MealsListScreen extends StatelessWidget {
  const MealsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Meals')), body: const Center(child: Text('Meals List Screen')));
  }
}
