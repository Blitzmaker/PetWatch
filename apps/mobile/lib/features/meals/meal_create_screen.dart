import 'package:flutter/material.dart';

class MealCreateScreen extends StatelessWidget {
  const MealCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Create Meal')), body: const Center(child: Text('Meal Create Screen')));
  }
}
